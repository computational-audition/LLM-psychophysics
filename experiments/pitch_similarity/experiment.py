# pylint: disable=unused-import,abstract-method,unused-argument,no-member

##########################################################################################
#### Imports
##########################################################################################

import logging
import rpdb
import random
import re
import time
import os
import warnings

from typing import Union, List
from dallinger import db
from flask import Markup

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__file__)

import psynet.experiment
from psynet.timeline import (
    Timeline,
    join,
    PageMaker,
    Event
)
from psynet.page import (
    InfoPage,
    SuccessfulEndPage,
    NumberInputPage,
    NAFCPage,
    TextInputPage,
    VolumeCalibration
)
from psynet.trial.static import (
    StimulusSpec,
    StimulusVersionSpec,
    StimulusSet,
    StaticTrialMaker,
    StaticTrial
)
from psynet.modular_page import (
    ModularPage,
    NumberControl,
    Prompt,
    PushButtonControl,
    TextControl,
    NAFCControl
)
from psynet.modular_page import ModularPage, Prompt, NAFCControl
from psynet.consent import PrincetonConsent
from psynet.prescreen import HeadphoneTest

CONFIG = {
    "num_experiment_trials": 80, #PER BLOCK! # 80
    "num_repeat_trials": 5,
    "target_num_trials_per_stimulus": 50,
    "num_of_blocks": 1
}

INITIAL_RECRUITMENT_SIZE = 40
WHICH_DATASET = "pitch_pairs_1"
WHICH_PRACTICE_DATASET = "pitch_pairs_1_practice"
EXPERIMENT_TYPE = "pitch" # for now "pitch" or "chord"


demographics = join(
    InfoPage("Before we finish, we need to ask some quick questions about you.", time_estimate=5), 
    ModularPage(
        "age",
        Prompt("Please indicate your age in years."),
        control=NumberControl(),
        time_estimate=3,
    ),
    ModularPage(
        "gender",
        Prompt("What gender do you identify as?"),
        control=PushButtonControl(
            ["Female", "Male", "Other"], arrange_vertically=False
        ),
        time_estimate=3,
    ),
    ModularPage(
        "education",
        Prompt("What is your highest educational qualification?"),
        control=PushButtonControl(
            [
                "None",
                "Elementary school",
                "Middle school",
                "High school",
                "University Undergraduate",
                "University Graduate",
                "University PhD"
            ],
            arrange_vertically=False,
        ),
        time_estimate=3,
    ),
    ModularPage(
        "country",
        Prompt(
            """
            What country are you from?
            """
        ),
        control=TextControl(one_line=True),
        time_estimate=3,
    ),
    ModularPage(
        "mother_tongue",
        Prompt(
            """
            What is your first language?
            """
        ),
        control=TextControl(one_line=True),
        time_estimate=3,
    ),
    ModularPage(
        "musical_experience",
        Prompt(
            """
            Have you ever played a musical instrument?
            """
        ),
        control=TextControl(one_line=True),
        time_estimate=3,
    ),
    ModularPage(
        "musical_instrument",
        Prompt(
            """
            If yes, which instrument? Otherwise, type none.
            """
        ),
        control=TextControl(one_line=True),
        time_estimate=3,
    ),
    ModularPage(
        "years_playing_music",
        Prompt("If yes, for how many years did you play? Please fill out even if the answer is zero."),
        control=NumberControl(),
        time_estimate=3,
    ),
)

final_questionnaire = join(
    ModularPage(
        "strategy",
        Prompt(
            """
        Please tell us in a few words about your experience taking the task.
        What was your strategy?
        Did you find the task easy or difficult?
        Did you find it interesting or boring?
        """
        ),
        control=TextControl(one_line=False),
        time_estimate=10,
    ),
    ModularPage(
        "technical",
        Prompt(
            """
        Did you experience any technical problems during the task?
        If so, please describe them.
        """
        ),
        control=TextControl(one_line=False),
        time_estimate=10,
    ),
)

class ChordPrompt(Prompt):
    macro = "chord_prompt"
    external_template = "chord_prompt.html"

    def __init__(self, chords, **kwargs):
        super().__init__(**kwargs)
        # rpdb.set_trace()
        self.chords = chords

    @property
    def metadata(self):
        return {
            **super().metadata,
            "chords": self.chords
        }


def make_timeline():
    return Timeline(
        PrincetonConsent(),
        VolumeCalibration(),
        HeadphoneTest(),
        instructions(),
        InfoPage("To help familiarize you with the task, you will first complete two practice trials.",time_estimate=5),
        make_practice_trials(),
        InfoPage(
            f"""
            The actual experiment will begin now. You will take up to
            {CONFIG['num_experiment_trials']*CONFIG["num_of_blocks"] + CONFIG['num_repeat_trials']} rounds
            where you have to answer this question. Remember to pay careful attention
            in order to get the best bonus!
            """,
            time_estimate=5
        ),
        make_experiment_trials(),
        demographics,
        final_questionnaire,
        InfoPage(Markup(
            """
            <strong>Attention</strong>: If you experience any problems in submitting the HIT, don't worry, just send us
            an email <strong>directly at </strong> with your accurate worker id and bonus.
            Please avoid using the automatic error boxes. This will help us compensate you appropriately.
            """
        ),time_estimate=5),
        SuccessfulEndPage()
    )

def instructions():
    return join(
        InfoPage(Markup(
            f"""
            <p>
                In this experiment we are studying how people perceive sounds. 
                In each round you will be presented with two sounds and 
                your task will be to simply judge how similar those sounds are.
            </p>
            <p>
                You will have seven response options, ranging from 0 ('Completely Dissimilar') to 6 ('Completely Similar').
                Choose the one you think is most appropriate. You will also have access to a replay button
                that will allow you to replay the sounds if needed.
            </p>
            <p>
                <strong>Note:</strong> no prior expertise is required to complete this task, just choose
                what you intuitively think is the right answer.
            </p>
            """),
            time_estimate=5
        ),
        InfoPage(
            """
            The quality of your responses will be automatically monitored,
            and you will receive a bonus at the end of the experiment
            in proportion to your quality score. The best way to achieve
            a high score is to concentrate and give each round your best attempt.
            """,
            time_estimate=5
        )
    )

def get_stimulus_set(phase: str): 
    import pandas as pd
    import json
    if phase == "experiment":
        df = pd.read_csv("stimuli/" + WHICH_DATASET + ".csv")
    else:
        df = pd.read_csv("stimuli/" + WHICH_PRACTICE_DATASET + ".csv")
    stimuli = [
        StimulusSpec(
            {
                "chords": {
                    "id": record["id"],
                    "f0_1": record["f0_1"],
                    "chord_1": record["chord_1"],
                    "f0_2": record["f0_2"],
                    "chord_2": record["chord_2"],
                    "idx_1": record["idx_1"],
                    "idx_2": record["idx_2"],
                    "synth": record["synth"],
                    "parametrization": record["parametrization"],
                    "shepardize": record["shepardize"],
                    "rolloff": record.get("rolloff"),
                    "custom_timbre": record.get("custom_timbre"),
                    "group": record.get("group"),
                    "block": record.get("block") if record.get("block") else "default",
                    "time_to_wait_in_sec": 4, # disables rating buttons until chord ends
                    "swap": random.randint(0,1) # whether to swap the stimuli, 0 = same order, 1 = swapped
                },
            "target": record["target"],
            "type": record["type"],
            },
            phase=phase,
            block= record.get("block") if record.get("block") else "default"
        )
        for record in df.to_dict("records")
    ]
    return StimulusSet("similarity_stimuli", stimuli)

nafc_choices = [
    (0, "(0) Completely Dissimilar"),
    (1, "(1) Very Dissimilar"),
    (2, "(2) Somewhat Dissimilar"),
    (3, "(3) Neither Similar nor Dissimilar"),
    (4, "(4) Somewhat Similar"),
    (5, "(5) Very Similar"),
    (6, "(6) Completely Similar"),
]

class RatingControl(NAFCControl):
    def __init__(self):
        super().__init__(
            choices=[x[0] for x in nafc_choices],
            labels=[x[1] for x in nafc_choices],
            arrange_vertically=False
            # min_width="125px"
        )

    def format_answer(self, raw_answer, **kwargs):
        return int(raw_answer)

class CustomTrial(StaticTrial):
    __mapper_args__ = {"polymorphic_identity": "custom_trial"}
    
    def show_trial(self, experiment, participant):
        if self.phase == "experiment":
            all_participant_trials = CustomTrial.query.filter_by(participant_id=participant.id).all()
            relevant_trials = [
                t 
                for t in all_participant_trials # assumes a single trial maker
                if t.phase == self.phase
                and t.failed
                == False
            ]
            current_number_of_trials = len(relevant_trials)
            trials_per_participant = CONFIG['num_experiment_trials']*CONFIG["num_of_blocks"] + CONFIG['num_repeat_trials']
            counter = f"({current_number_of_trials} / {trials_per_participant})"
        else:
            counter = ""
            if EXPERIMENT_TYPE == "pitch":
                # randomize over practice pitch by sampling a random pair without replacement
                random_pair = random.sample([i for i in range(60,85)], 2) 
                self.definition["chords"]["f0_1"]=random_pair[0]
                self.definition["chords"]["f0_2"]=random_pair[1]

        prompt = Markup(
            f"""
            <p>
                How similar are the pair of sounds you just heard? {counter}
            </p>
            <p>
                If it is difficult to choose between the options,
                don't worry, and just give what you intuitively think is the right answer.
            </p>
            """
        )

        return ModularPage(
            "custom_trial",
            ChordPrompt(self.definition, text=prompt, text_align="center"),
            RatingControl()
        )

class CustomTrialMaker(StaticTrialMaker):
    give_end_feedback_passed = False
    performance_threshold = -1.0

    def compute_bonus(self, score, passed):
        if self.phase == "practice":
            return 0.0
        elif self.phase == "experiment":
            if score is None:
                return 0.0
            else:
                return min(max(0.0, 0.1*score),0.1)
        else:
            raise NotImplementedError

def make_experiment_trials():
    return CustomTrialMaker(
        id_="main_experiment",
        trial_class=CustomTrial,
        phase="experiment",
        stimulus_set=get_stimulus_set(phase="experiment"),
        recruit_mode="num_trials",
        target_num_participants=None,
        target_num_trials_per_stimulus=CONFIG["target_num_trials_per_stimulus"],
        max_trials_per_block=CONFIG["num_experiment_trials"],
        allow_repeated_stimuli=True,
        max_unique_stimuli_per_block=None,
        active_balancing_within_participants=True,
        active_balancing_across_participants=True,
        check_performance_at_end=True,
        check_performance_every_trial=False,
        fail_trials_on_premature_exit=False,
        fail_trials_on_participant_performance_check=False,
        num_repeat_trials=CONFIG["num_repeat_trials"],
        time_estimate_per_trial=7
    )

def make_practice_trials():
    return CustomTrialMaker(
        id_="main_practice",
        trial_class=CustomTrial,
        phase="practice",
        stimulus_set=get_stimulus_set(phase="practice"),
        recruit_mode="num_participants",
        target_num_participants=0,
        max_trials_per_block=CONFIG["num_experiment_trials"],
        allow_repeated_stimuli=False,
        max_unique_stimuli_per_block=None,
        active_balancing_within_participants=True,
        active_balancing_across_participants=True,
        check_performance_at_end=False,
        check_performance_every_trial=False,
        fail_trials_on_premature_exit=False,
        fail_trials_on_participant_performance_check=False,
        num_repeat_trials=0,
        time_estimate_per_trial=7
    )

class Exp(psynet.experiment.Experiment):
    variables = {
        "wage_per_hour": 12.0,
        "show_bonus": False,
        "soft_max_experiment_payment": 2000.0,
        "hard_max_experiment_payment": 2500.0
    }
    timeline = make_timeline()

    def __init__(self, session=None):
        super().__init__(session)
        self.initial_recruitment_size = INITIAL_RECRUITMENT_SIZE


