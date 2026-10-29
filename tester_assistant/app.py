"""German desktop interface for a local, deliberate beta return workflow."""

from __future__ import annotations

import argparse
import json
import os
from pathlib import Path
import subprocess
import sys
import tkinter as tk
from tkinter import filedialog, messagebox, ttk
from typing import Sequence
from urllib.parse import urlsplit
import webbrowser

from .bundle import BundleResult
from .controller import BetaTestController, WizardState, WizardStep
from .diagnostics import DiagnosticReport
from .questionnaire import QuestionDefinition, load_questions


_STEP_TITLES = {
    WizardStep.ASSIGNMENT: "1. Testauftrag",
    WizardStep.EXPORT: "2. Originalexport",
    WizardStep.DIAGNOSTICS: "3. Diagnose",
    WizardStep.QUESTIONNAIRE: "4. Fragebogen",
    WizardStep.RETURN: "5. Rückgabe",
}
_DIAGNOSTIC_MESSAGES = {
    "unreadable_input": "Die Datei konnte nicht gelesen werden.",
    "empty_input": "Die Datei ist leer.",
    "zip_unsafe_member_name": "Das ZIP enthält einen unsicheren Dateinamen.",
    "zip_unsafe_member_type": "Das ZIP enthält einen unerlaubten Dateityp.",
    "zip_nested_archive": "Das ZIP enthält ein weiteres Archiv.",
    "zip_executable_member": "Das ZIP enthält eine ausführbare Datei.",
    "zip_no_fit": "Im ZIP wurde keine FIT-Datei gefunden.",
    "zip_multiple_fit": "Im ZIP wurden mehrere FIT-Dateien gefunden.",
    "zip_unexpected_member": "Das ZIP enthält eine unerwartete Datei.",
    "fit_too_large": "Die FIT-Datei ist zu groß.",
    "empty_fit": "Die FIT-Datei ist leer.",
    "unsupported_zip_compression": "Die ZIP-Komprimierung wird nicht unterstützt.",
    "corrupt_zip": "Das ZIP ist beschädigt oder nicht lesbar.",
    "invalid_metric": "Die Messwerte konnten nicht geprüft werden.",
    "parser_error": "Die FIT-Datei konnte nicht ausgewertet werden.",
    "schema_mismatch": "Das FIT-Schema passt nicht zu Beta 6.",
    "missing_session_start": "Der Beginn der Einheit fehlt.",
    "invalid_duration": "Die Dauer der Einheit ist ungültig.",
    "unsupported_extension": "Bitte eine Originaldatei als FIT oder ZIP wählen.",
    "original_name_mismatch": "Der Dateiname passt nicht zum Testauftrag.",
}


def step_title(step: WizardStep) -> str:
    return _STEP_TITLES[step]


def diagnostic_message(code: str | None) -> str:
    return _DIAGNOSTIC_MESSAGES.get(code, "Die Diagnose ist nicht verfügbar. Bitte Datei und Testauftrag prüfen.")


def rating_label(value: int | str) -> str:
    return "Nicht zutreffend" if value == "not_applicable" else str(value)


def privacy_text() -> str:
    return load_questions()[0].privacy_warning


def questionnaire_items() -> tuple[tuple[int, QuestionDefinition], ...]:
    return tuple(enumerate(load_questions(), start=1))


def button_state(state: WizardState) -> dict[str, bool]:
    """Return high-level capability gates; widgets may narrow them by displayed page."""
    return {
        "back": state.step not in (WizardStep.ASSIGNMENT, WizardStep.RETURN),
        "next": {
            WizardStep.ASSIGNMENT: state.assignment is not None,
            WizardStep.EXPORT: state.diagnostics is not None,
            WizardStep.DIAGNOSTICS: state.diagnostics is not None,
            WizardStep.QUESTIONNAIRE: state.answers is not None,
            WizardStep.RETURN: False,
        }[state.step],
        "open_upload": state.step is WizardStep.RETURN and state.bundle is not None,
    }


def selection_texts(state: WizardState) -> dict[str, str]:
    """Summaries come from the current snapshot, so invalidation clears the display."""
    return {
        "assignment": str(state.assignment_path) if state.assignment_path else "Kein Testauftrag ausgewählt.",
        "original": str(state.original_path) if state.original_path else "Kein Originalexport ausgewählt.",
    }


def _optional(value: object, suffix: str = "") -> str:
    return f"{value}{suffix}" if value is not None else "Nicht verfügbar"


def diagnostic_rows(report: DiagnosticReport | None) -> tuple[tuple[str, str], ...]:
    if report is None:
        return tuple((label, "Nicht verfügbar") for label in (
            "Original SHA-256", "FIT SHA-256", "Erwarteter PRG SHA-256", "Schema",
            "Beginn", "Dauer", "Manuelle Shifts", "Geschätzte Distanz",
            "Persönlicher Faktor", "Herzfrequenz",
        ))
    return (
        ("Original SHA-256", _optional(report.original_sha256 or None)),
        ("FIT SHA-256", _optional(report.fit_sha256 or None)),
        ("Erwarteter PRG SHA-256", _optional(report.expected_prg_sha256 or None)),
        ("Schema", _optional(report.schema_version)),
        ("Beginn", _optional(report.session_start or None)),
        ("Dauer", _optional(f"{report.duration_minutes:g}", " Minuten")),
        ("Manuelle Shifts", _optional(report.manual_shift_count)),
        ("Geschätzte Distanz", _optional(f"{report.estimated_distance_m:g}" if report.estimated_distance_m is not None else None, " m")),
        ("Persönlicher Faktor", _optional(f"{report.personal_calibration_factor:g}" if report.personal_calibration_factor is not None else None)),
        ("Herzfrequenz", "Vorhanden" if report.heart_rate_available else "Nicht verfügbar"),
    )


def validated_upload_url(bundle: BundleResult | None, url: str | None) -> str | None:
    """Recheck the controller-provided URL at the browser boundary."""
    if (bundle is None or not bundle.path.is_file() or not isinstance(url, str)
            or any(char.isspace() for char in url)):
        return None
    try:
        parsed = urlsplit(url)
        parsed.port
    except ValueError:
        return None
    if (parsed.scheme.lower() != "https" or not parsed.hostname or
            parsed.username is not None or parsed.password is not None or parsed.fragment):
        return None
    return url


def bind_questionnaire_wheel(canvas: tk.Canvas, content: ttk.Frame) -> None:
    """Scroll over every questionnaire child without changing app-wide bindings."""
    def on_wheel(event: tk.Event) -> str:
        delta = event.delta
        if delta:
            units = max(1, abs(delta) // 120)
            canvas.yview_scroll(-units if delta > 0 else units, "units")
        return "break"

    def bind_tree(widget: tk.Widget) -> None:
        widget.bind("<MouseWheel>", on_wheel)
        for child in widget.winfo_children():
            bind_tree(child)

    bind_tree(canvas)
    bind_tree(content)


class BetaTestApp:
    """One-frame-per-step view bound only to the local controller API."""

    def __init__(self, root: tk.Tk, controller: BetaTestController):
        self.root = root
        self.controller = controller
        self.view_step = WizardStep.ASSIGNMENT
        self.pages: dict[WizardStep, ttk.Frame] = {}
        self.root.title("RinkLogic Beta 6 – Testassistent")
        self.root.geometry("900x740")
        self.root.minsize(620, 500)
        self.root.columnconfigure(0, weight=1)
        self.root.rowconfigure(0, weight=1)
        self.status = tk.StringVar(value=controller.state_snapshot().status_summary)
        self.assignment_text = tk.StringVar(value="Kein Testauftrag ausgewählt.")
        self.original_text = tk.StringVar(value="Kein Originalexport ausgewählt.")
        self.bundle_text = tk.StringVar(value="Noch kein Rückgabepaket erstellt.")
        self.rating_vars: dict[str, tk.StringVar] = {}
        self._first_focus: dict[WizardStep, tk.Widget] = {}
        self._navigation: dict[WizardStep, tuple[ttk.Button | None, ttk.Button | None]] = {}
        self._build_pages()
        self._refresh()

    def _page(self, step: WizardStep) -> ttk.Frame:
        page = ttk.Frame(self.root, padding=20)
        page.grid(row=0, column=0, sticky="nsew")
        page.columnconfigure(0, weight=1)
        self.pages[step] = page
        ttk.Label(page, text=step_title(step), font=("TkDefaultFont", 16, "bold")).grid(
            row=0, column=0, sticky="w", pady=(0, 12))
        return page

    def _label(self, parent: tk.Widget, text: str, row: int) -> None:
        ttk.Label(parent, text=text, wraplength=780, justify="left").grid(
            row=row, column=0, sticky="ew", pady=(0, 10))

    def _footer(self, step: WizardStep, row: int, *, next_text: str = "Weiter") -> None:
        page = self.pages[step]
        footer = ttk.Frame(page)
        footer.grid(row=row, column=0, sticky="ew", pady=(16, 0))
        footer.columnconfigure(1, weight=1)
        back = None
        if step not in (WizardStep.ASSIGNMENT, WizardStep.RETURN):
            back = ttk.Button(footer, text="Zurück", command=self._back)
            back.grid(row=0, column=0, sticky="w")
        next_button = None
        if step is not WizardStep.RETURN:
            next_button = ttk.Button(footer, text=next_text, command=self._next)
            next_button.grid(row=0, column=2, sticky="e")
        self._navigation[step] = (back, next_button)
        ttk.Label(page, textvariable=self.status, wraplength=780, justify="left").grid(
            row=row + 1, column=0, sticky="ew", pady=(12, 0))

    def _build_pages(self) -> None:
        page = self._page(WizardStep.ASSIGNMENT)
        self._label(page, "Wähle den erhaltenen Beta-6-Testauftrag (JSON). Der Assistent arbeitet lokal und fragt keine Garmin-Zugangsdaten ab.", 1)
        select = ttk.Button(page, text="Testauftrag auswählen …", command=self._choose_assignment)
        select.grid(row=2, column=0, sticky="w")
        self._first_focus[WizardStep.ASSIGNMENT] = select
        ttk.Label(page, textvariable=self.assignment_text, wraplength=780).grid(row=3, column=0, sticky="w", pady=10)
        self._footer(WizardStep.ASSIGNMENT, 4)

        page = self._page(WizardStep.EXPORT)
        self._label(page, "Garmin Connect Web öffnen → Aktivität wählen → „Export Original“ herunterladen. Die unveränderte FIT- oder ZIP-Datei hier auswählen. Keine Zugangsdaten eingeben.", 1)
        select = ttk.Button(page, text="Originalexport auswählen …", command=self._choose_original)
        select.grid(row=2, column=0, sticky="w")
        self._first_focus[WizardStep.EXPORT] = select
        ttk.Label(page, textvariable=self.original_text, wraplength=780).grid(row=3, column=0, sticky="w", pady=10)
        self._footer(WizardStep.EXPORT, 4)

        page = self._page(WizardStep.DIAGNOSTICS)
        self._label(page, "Lokale Prüfung des Originalexports. Die Distanz ist eine experimentelle Schätzung; diese Anzeige bewertet weder Genauigkeit noch Gesundheit oder Freigabe.", 1)
        details = ttk.Frame(page)
        details.grid(row=2, column=0, sticky="nsew")
        details.columnconfigure(1, weight=1)
        self.diagnostic_values: dict[str, tk.StringVar] = {}
        for index, (label, _) in enumerate(diagnostic_rows(None)):
            ttk.Label(details, text=f"{label}:").grid(row=index, column=0, sticky="nw", padx=(0, 16), pady=3)
            variable = tk.StringVar(value="Nicht verfügbar")
            self.diagnostic_values[label] = variable
            ttk.Label(details, textvariable=variable, wraplength=590).grid(row=index, column=1, sticky="w", pady=3)
        self._footer(WizardStep.DIAGNOSTICS, 3)
        self._first_focus[WizardStep.DIAGNOSTICS] = self._navigation[WizardStep.DIAGNOSTICS][1]

        page = self._page(WizardStep.QUESTIONNAIRE)
        page.rowconfigure(2, weight=1)
        self._label(page, "Bitte beantworte alle zehn Fragen. Die Bewertungsskala ist 1 bis 5; „Nicht zutreffend“ ist möglich.", 1)
        scroll_host = ttk.Frame(page)
        scroll_host.grid(row=2, column=0, sticky="nsew")
        scroll_host.rowconfigure(0, weight=1)
        scroll_host.columnconfigure(0, weight=1)
        canvas = tk.Canvas(scroll_host, highlightthickness=0)
        scrollbar = ttk.Scrollbar(scroll_host, orient="vertical", command=canvas.yview)
        canvas.configure(yscrollcommand=scrollbar.set)
        canvas.grid(row=0, column=0, sticky="nsew")
        scrollbar.grid(row=0, column=1, sticky="ns")
        content = ttk.Frame(canvas, padding=(0, 0, 12, 0))
        window_id = canvas.create_window((0, 0), window=content, anchor="nw")
        content.bind("<Configure>", lambda _event: canvas.configure(scrollregion=canvas.bbox("all")))
        canvas.bind("<Configure>", lambda event: canvas.itemconfigure(window_id, width=event.width))
        canvas.bind("<Prior>", lambda _event: canvas.yview_scroll(-1, "pages"))
        canvas.bind("<Next>", lambda _event: canvas.yview_scroll(1, "pages"))
        ttk.Label(content, text=privacy_text(), wraplength=740, justify="left").grid(
            row=0, column=0, sticky="ew", pady=(0, 12))
        for number, question in questionnaire_items():
            row = number * 2
            ttk.Label(content, text=f"{number}. {question.prompt}", wraplength=740,
                      justify="left").grid(row=row, column=0, sticky="ew", pady=(8, 2))
            if question.choices is None:
                self.improvement = tk.Text(content, height=4, width=70, wrap="word")
                self.improvement.grid(row=row + 1, column=0, sticky="ew")
                self.improvement.bind("<FocusIn>", lambda _event, widget=self.improvement: canvas.yview_moveto(
                    max(0.0, widget.winfo_y() / max(1, content.winfo_height()))))
            else:
                variable = tk.StringVar(value="")
                self.rating_vars[question.question_id] = variable
                choices = [rating_label(choice) for choice in question.choices]
                control = ttk.Combobox(content, textvariable=variable, values=choices,
                                       state="readonly", width=22)
                control.grid(row=row + 1, column=0, sticky="w")
                control.bind("<FocusIn>", lambda _event, widget=control: canvas.yview_moveto(
                    max(0.0, widget.winfo_y() / max(1, content.winfo_height()))))
                if number == 1:
                    self._first_focus[WizardStep.QUESTIONNAIRE] = control
        ttk.Label(content, text="Optional: Probleme oder Abstürze genauer beschreiben (ohne private Angaben).",
                  wraplength=740).grid(row=22, column=0, sticky="w", pady=(16, 2))
        self.problem_details = tk.Text(content, height=4, width=70, wrap="word")
        self.problem_details.grid(row=23, column=0, sticky="ew")
        self.problem_details.bind("<FocusIn>", lambda _event: canvas.yview_moveto(1.0))
        bind_questionnaire_wheel(canvas, content)
        ttk.Button(page, text="Antworten prüfen", command=self._check_answers).grid(
            row=3, column=0, sticky="w", pady=(8, 0))
        self._footer(WizardStep.QUESTIONNAIRE, 4, next_text="Rückgabepaket erstellen …")

        page = self._page(WizardStep.RETURN)
        self._label(page, "Das Rückgabepaket wurde lokal erstellt. Bitte über den privaten Kanal selbst hochladen. Der Assistent sendet keine Datei und bestätigt keinen Eingang.", 1)
        ttk.Label(page, textvariable=self.bundle_text, wraplength=780, justify="left").grid(
            row=2, column=0, sticky="ew", pady=(0, 20))
        actions = ttk.Frame(page)
        actions.grid(row=3, column=0, sticky="w")
        folder = ttk.Button(actions, text="Ordner öffnen", command=self._open_folder)
        folder.grid(row=0, column=0, padx=(0, 8))
        upload = ttk.Button(actions, text="Upload-Seite öffnen", command=self._open_upload)
        upload.grid(row=0, column=1, padx=(0, 8))
        ttk.Button(actions, text="Fertig", command=self.root.destroy).grid(row=0, column=2)
        self.upload_button = upload
        self._first_focus[WizardStep.RETURN] = folder
        self._footer(WizardStep.RETURN, 4)

    def _refresh(self) -> None:
        state = self.controller.state_snapshot()
        self.status.set(state.status_summary + (
            f" {diagnostic_message(state.diagnostic_code)}" if state.diagnostic_code else ""))
        selections = selection_texts(state)
        self.assignment_text.set(selections["assignment"])
        self.original_text.set(selections["original"])
        for label, value in diagnostic_rows(state.diagnostics):
            self.diagnostic_values[label].set(value)
        if state.bundle is not None:
            bundle = state.bundle
            self.bundle_text.set(
                f"Datei: {bundle.path}\nSHA-256: {bundle.sha256}\nInhalt: " +
                ", ".join(bundle.member_names))
        else:
            self.bundle_text.set("Noch kein Rückgabepaket erstellt.")
        self.upload_button.configure(state="normal" if button_state(state)["open_upload"] else "disabled")
        for step, (_back, next_button) in self._navigation.items():
            if next_button is None:
                continue
            ready = {
                WizardStep.ASSIGNMENT: state.assignment is not None,
                WizardStep.EXPORT: state.diagnostics is not None,
                WizardStep.DIAGNOSTICS: state.diagnostics is not None,
                WizardStep.QUESTIONNAIRE: state.answers is not None,
            }[step]
            next_button.configure(state="normal" if ready else "disabled")
        self.pages[self.view_step].tkraise()
        focus = self._first_focus.get(self.view_step)
        if focus is not None:
            focus.focus_set()

    def _choose_assignment(self) -> None:
        path = filedialog.askopenfilename(parent=self.root, title="Testauftrag auswählen",
                                          filetypes=[("JSON", "*.json"), ("Alle Dateien", "*.*")])
        if path:
            self.controller.load_assignment(path)
            self._refresh()

    def _choose_original(self) -> None:
        path = filedialog.askopenfilename(parent=self.root, title="Originalexport auswählen",
                                          filetypes=[("FIT oder ZIP", "*.fit *.zip"), ("Alle Dateien", "*.*")])
        if path:
            self.controller.select_original(path)
            self._refresh()

    def _raw_answers(self) -> dict[str, object]:
        result: dict[str, object] = {}
        for question_id, variable in self.rating_vars.items():
            value = variable.get()
            if value == rating_label("not_applicable"):
                result[question_id] = "not_applicable"
            elif value in {"1", "2", "3", "4", "5"}:
                result[question_id] = int(value)
            else:
                result[question_id] = value
        result["priority_improvement"] = self.improvement.get("1.0", "end-1c")
        details = self.problem_details.get("1.0", "end-1c")
        if details.strip():
            result["problem_details"] = details
        return result

    def _check_answers(self) -> None:
        self.controller.submit_answers(self._raw_answers())
        self._refresh()

    def _back(self) -> None:
        if self.controller.state_snapshot().step is WizardStep.RETURN:
            self.view_step = WizardStep.RETURN
            self._refresh()
            return
        steps = list(WizardStep)
        index = steps.index(self.view_step)
        if index > 0:
            self.view_step = steps[index - 1]
            self._refresh()

    def _next(self) -> None:
        state = self.controller.state_snapshot()
        if state.step is WizardStep.RETURN:
            self.view_step = WizardStep.RETURN
            self._refresh()
            return
        if self.view_step is WizardStep.ASSIGNMENT and state.assignment is not None:
            self.view_step = WizardStep.EXPORT
        elif self.view_step is WizardStep.EXPORT and state.diagnostics is not None:
            self.view_step = WizardStep.DIAGNOSTICS
        elif self.view_step is WizardStep.DIAGNOSTICS:
            if state.step is WizardStep.DIAGNOSTICS:
                state = self.controller.continue_to_questionnaire()
            if state.step is WizardStep.QUESTIONNAIRE:
                self.view_step = WizardStep.QUESTIONNAIRE
        elif self.view_step is WizardStep.QUESTIONNAIRE:
            state = self.controller.submit_answers(self._raw_answers())
            if state.answers is None:
                self._refresh()
                return
            destination = filedialog.askdirectory(parent=self.root, title="Speicherort für Rückgabepaket wählen")
            if not destination:
                return
            if not messagebox.askyesno("Rückgabepaket erstellen",
                                       "Das Rückgabepaket mit Originalexport und Antworten jetzt lokal erstellen?",
                                       parent=self.root):
                return
            state = self.controller.create_bundle(destination)
            if state.step is WizardStep.RETURN:
                self.view_step = WizardStep.RETURN
        self._refresh()

    def _open_folder(self) -> None:
        bundle = self.controller.state_snapshot().bundle
        if bundle is None:
            return
        folder = bundle.path.parent
        try:
            if sys.platform == "win32":
                os.startfile(folder)  # type: ignore[attr-defined]
            elif sys.platform == "darwin":
                subprocess.Popen(["open", str(folder)])
            else:
                subprocess.Popen(["xdg-open", str(folder)])
        except OSError:
            messagebox.showerror("Ordner öffnen", "Der Ordner konnte nicht geöffnet werden.", parent=self.root)

    def _open_upload(self) -> None:
        state = self.controller.state_snapshot()
        url = validated_upload_url(state.bundle, self.controller.upload_url())
        if url is None:
            messagebox.showerror("Upload-Seite", "Die Upload-Seite ist nicht verfügbar.", parent=self.root)
            return
        if messagebox.askyesno("Upload-Seite öffnen",
                               "Die private Upload-Seite im Browser öffnen? Das Rückgabepaket wird nicht automatisch gesendet.",
                               parent=self.root):
            webbrowser.open(url)


def build_app(root: tk.Tk | None = None) -> BetaTestApp:
    return BetaTestApp(root if root is not None else tk.Tk(), BetaTestController())


def self_check() -> dict[str, object]:
    """Offline/package check that deliberately never constructs a Tk root."""
    questions = questionnaire_items()
    state = BetaTestController().state_snapshot()
    return {
        "self_check": "ok" if len(questions) == 10 and state.step is WizardStep.ASSIGNMENT else "failed",
        "question_count": len(questions),
        "step_count": len(WizardStep),
    }


def main(argv: Sequence[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description="Lokaler RinkLogic Beta-6-Testassistent")
    parser.add_argument("--self-check", action="store_true", help="Offline-Paketprüfung ohne Fenster")
    args = parser.parse_args(argv)
    if args.self_check:
        result = self_check()
        print(json.dumps(result, ensure_ascii=False))
        return 0 if result["self_check"] == "ok" else 1
    app = build_app()
    app.root.mainloop()
    return 0
