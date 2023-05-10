from flask import Markup

from psynet.modular_page import (
    AudioPrompt,
    ModularPage,
    PushButtonControl,
)
from psynet.page import InfoPage
from psynet.timeline import (
    Module,
    join,
)
from psynet.trial.static import StaticTrial, StaticTrialMaker, StimulusSet, StimulusSpec


class ConsonantTest(Module):
    """

    Parameters
    ----------

    label : string, optional
        The label for the test, default: "consonant_test".

    time_estimate_per_trial : float, optional
        The time estimate in seconds per trial, default: 2.0.

    performance_threshold : int, optional
        The performance threshold, default: 2.

    num_trials : float, optional
        The total number of trials to display, default: 3.


    """

    def __init__(
        self,
        label="consonant_test",
        time_estimate_per_trial: float = 2.0,
        performance_threshold: int = 0,
        media_url: str = "https://mini-kinetics-psy.s3.amazonaws.com/vocal_consonants/consonants/male/ipachart-com",
        num_trials: float = 3,
    ):
        self.label = label
        self.elts = join(
            self.instruction_page(num_trials),
            self.trial_maker(
                media_url,
                time_estimate_per_trial,
                performance_threshold,
                num_trials,
            ),
        )
        super().__init__(self.label, self.elts)

    def instruction_page(self, num_trials):
        return InfoPage(
            Markup(
                # TODO Explain what consonants are as opposed to vowels + examples, 
                # on the next page you will hear vowels and a consonant and they will have
                # to select the right consonant from the list
                # for example you will hear "aba" and you should select the consonant "b"
                        f"""
               <h3>Consonant test</h3>
                <p>To help familiarize you with the sound of consonants, you will listen to recordings of individual consonants.</p>
                <p>
                    <b>Your task will be to guess which consonant letter you just heard.</b>
                </p>
                """
            ),
            time_estimate=5,
        )

    def trial_maker(
        self,
        media_url: str,
        time_estimate_per_trial: float,
        performance_threshold: int,
        num_trials: float,
    ):
        class TrialMaker(StaticTrialMaker):
            def performance_check(self, experiment, participant, participant_trials):
                """Should return a dict: {"score": float, "passed": bool}"""
                score = 0
                for trial in participant_trials:
                    if trial.answer == trial.definition["correct_answer"]:
                        score += 1
                passed = score >= performance_threshold
                return {"score": score, "passed": passed}

        return TrialMaker(
            id_="consonant",
            trial_class=self.trial(time_estimate_per_trial),
            phase="screening",
            stimulus_set=self.get_stimulus_set(media_url),
            max_trials_per_block=num_trials,
            check_performance_at_end=True,
        )

    def trial(self, time_estimate_: float):
        class Trial(StaticTrial):
            time_estimate = time_estimate_

            def show_trial(self, experiment, participant):
                answers = ["s", "f", "g", "k", "t", "d", "p", "b", "m", "n"]
                return ModularPage(
                    "consonant_trial",
                    AudioPrompt(
                        self.definition["url"],
                        "Select the consonant you hear",
                    ),
                    PushButtonControl(
                        answers,
                        answers,
                        arrange_vertically=False,
                        style="min-width: 150px; margin: 10px",
                    ),
                    time_estimate=self.time_estimate,
                )

        return Trial

    def get_stimulus_set(self, media_url: str):
        return StimulusSet(
            "stimuli",
            [
                StimulusSpec(
                    definition={
                        "label": name,
                        "correct_answer": correct_answer,
                        "url": f"{media_url}/{name}.mp3",
                    },
                    phase="screening",
                )
                for name, correct_answer in [
                    ("Voiceless_alveolar_fricative", "s"),
                    ("Voiceless_velar_plosive", "k"),
                    ("Voiced_alveolar_plosive", "d"),
                ]
            ],
        )