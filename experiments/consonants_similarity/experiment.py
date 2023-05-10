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
import numpy as np

from typing import Union, List
from dallinger import db
from flask import Markup
from math import isnan

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
from psynet.consent import PrincetonConsent, MainConsent
from psynet.prescreen import LanguageVocabularyTest, LexTaleTest, HeadphoneTest
from .consonant import ConsonantTest

CONFIG = {
    "num_experiment_trials": 50, #PER BLOCK! # 80
    "num_repeat_trials": 5,
    "target_num_trials_per_stimulus": 10,
    "num_of_blocks": 1
}

INITIAL_RECRUITMENT_SIZE = 30
WHICH_DATASET = "vocal_consonant_stimuli_pairs"
BASE_URL = "https://mini-kinetics-psy.s3.amazonaws.com/vocal_consonants/consonants/"

demographics = join(
    InfoPage("You reached the end of the experiment! Before we finish, we need to ask some quick questions about you.", time_estimate=5), 
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
    )
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


def make_timeline():
    return Timeline(
        MainConsent(),
        InfoPage("Before the actual experiment begins, we'd like you to complete a prescreening test.", time_estimate=2),
        VolumeCalibration(),
        HeadphoneTest(),
        LexTaleTest(),
        instructions(),
        ConsonantTest(),
        InfoPage(
            f"""
            The experiment will begin now. You will take up to
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
            an email <strong>directly at computational.audition+raja@gmail.com</strong> with your accurate worker id and bonus.
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
            Please pay attention to the following instructions:
            <ul>
                <li>In this experiment we are studying how people perceive the sound of vocal consonants.</li>
                <li>A <strong><strong>consonant</strong></strong> is a speech sound that is pronounced by partly blocking air from the vocal tract.</li>
                <li>For example, the sound of the letter "c" in "cat" is a consonant, and so is "t" but not "a".</li>
                <li>Similarly, the sound of the combination "sh" in "sheep" is a consonant, and so is "p" but not "ee".</li>
                <li>In general, vowel sounds like those of the letters a, e, i, o, u are <strong><strong>not consonants.</strong></strong></li>
            </ul>
            </p>
            <p>
                In each round you will be presented with two different recordings each including one consonant sound and 
                your task will be to simply judge <strong><strong>how similar are the sounds of the two spoken consonants</strong></strong>.
            </p>
            <p>
                We are <strong><strong>not interested</strong></strong> in the vowel sounds nor in the voice height, just the sound of the consonants.
            </p>
            <p>
                You will have seven response options, ranging from 0 ('Completely Dissimilar') to 6 ('Completely Similar'). Choose the one you think is most appropriate.
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
    df = pd.read_csv("stimuli/" + WHICH_DATASET + ".csv")
    df = df.sample(frac=1) # shuffle data frame to ensure mixing
    stimuli = [
        StimulusSpec(
            {
                "id": record["id"],
                "stim_1": BASE_URL + record["sex_1"] + '/' + record["dataset_1"] + '/' + record["speaker_1"] + '/' + record["stim_1"],
                "stim_2": BASE_URL + record["sex_2"] + '/' + record["dataset_2"] + '/' + record["speaker_2"] + '/' + record["stim_2"],
                "idx_1": record["idx_1"],
                "idx_2": record["idx_2"],
                "sex_1": record["sex_1"],
                "sex_2": record["sex_2"],
                "dataset_1": record["dataset_1"],
                "dataset_2": record["dataset_2"],
                "speaker_1": record["speaker_1"],
                "speaker_2": record["speaker_2"],                                               
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

class AudioPrompt(Prompt):
    macro = "audio_prompt"
    external_template = "audio_prompt.html"

    def __init__(self, definition, **kwargs):
        super().__init__(**kwargs)
        self.definition = definition

    @property
    def metadata(self):
        return {
            **super().metadata,
            "definition": self.definition
        }

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
    time_estimate = 6
    
    def show_trial(self, experiment, participant):
        all_participant_trials = CustomTrial.query.filter_by(participant_id=participant.id).all()
        relevant_trials = [
            t 
            for t in all_participant_trials # assumes a single trial maker
            if t.phase == self.phase
            and t.failed == False
        ]
        current_number_of_trials = len(relevant_trials)
        trials_per_participant = CONFIG['num_experiment_trials']*CONFIG["num_of_blocks"] + CONFIG['num_repeat_trials']
        counter = f"({current_number_of_trials} / {trials_per_participant})"
        order = random.randint(0,1)
        options = [self.definition["stim_1"], self.definition["stim_2"]]
        prompt = Markup(
            f"""
            <p>
                How similar is the sound of the <strong>consonants</strong> pronounced by the two speakers? {counter}
            </p>
            <p>
                If it is difficult to choose between the options,
                don't worry, and just give what you intuitively think is the right answer.
            </p>
            """
        )

        return ModularPage(
            "custom_trial",
            AudioPrompt({"stim_1": options[order], "stim_2": options[1-order]}, text=prompt, text_align="center"),
            RatingControl()
        )

class CustomTrialMaker(StaticTrialMaker):
    give_end_feedback_passed = False
    performance_threshold = -1.0

    def performance_check_consistency(
        self, experiment, participant, participant_trials
    ):
        trials_by_id = {trial.id: trial for trial in participant_trials}

        repeat_trials = [t for t in participant_trials if t.is_repeat_trial]
        parent_trials = [trials_by_id[t.parent_trial_id] for t in repeat_trials]

        repeat_trial_answers = [
            self.get_answer_for_consistency_check(t) for t in repeat_trials
        ]
        parent_trial_answers = [
            self.get_answer_for_consistency_check(t) for t in parent_trials
        ]

        assert self.min_nodes_for_performance_check >= 2

        if len(repeat_trials) < self.min_nodes_for_performance_check:
            logger.info(
                "min_nodes_for_performance_check was not reached, so consistency score cannot be calculated."
            )
            score = None
            passed = True
        else:
            consistency = self.get_consistency(
                repeat_trial_answers, parent_trial_answers
            )
            if isnan(consistency):
                logger.info(
                    """
                    get_consistency returned 'nan' in the performance check.
                    This commonly indicates that the participant gave the same response
                    to all repeat trials. The participant will NOT be failed.
                    """
                )
                score = None
                passed = True
            else:
                score = float(consistency)
                passed = bool(score >= self.performance_threshold)
        logger.info(
            "Performance check for participant %i: consistency = %s, passed = %s",
            participant.id,
            "NA" if score is None else f"{score:.3f}",
            passed,
        )
        return {"score": score, "passed": passed}

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
        #time_estimate_per_trial=4
    )

class Exp(psynet.experiment.Experiment):
    variables = {
        "wage_per_hour": 9.0,
        "show_bonus": False,
        "soft_max_experiment_payment": 2000.0,
        "hard_max_experiment_payment": 2500.0
    }
    timeline = make_timeline()

    def __init__(self, session=None):
        super().__init__(session)
        self.initial_recruitment_size = INITIAL_RECRUITMENT_SIZE


