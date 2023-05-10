# pylint: disable=unused-import,abstract-method
import json
import os

import random
from typing import List, Union

import pandas as pd
from flask import Markup

import psynet.experiment
from psynet.consent import MainConsent
from psynet.modular_page import ModularPage, PushButtonControl, Prompt, Control
from psynet.page import SuccessfulEndPage, InfoPage
from psynet.timeline import Timeline, PageMaker, join, switch
from psynet.trial.static import StaticNode, StaticTrial, StaticTrialMaker
from psynet.utils import get_logger
from psynet.prescreen import ColorBlindnessTest
from psynet.utils import get_translator

logger = get_logger()

LANGUAGE = "en"
SUPPORTED_LANGUAGES = ['en', 'ru', 'he']

colors_data = pd.read_csv("data_WCS.csv").to_dict("records")
COLOR_LABELS = {
    "en": ["Green", "Turquoise", "Blue", "Purple", "Pink", "Brown", "Yellow", "Orange", "Red", "Gray", "Beige", "Gold",
           "Silver", "Black"],
    "ru": ["Красный", "Оранжевый", "Желтый", "Зеленый", "Голубой", "Синий", "Фиолетовый", "Белый", "Черный", "Серый",
           "Коричневый", "Розовый", "Бирюзовый", "Бежевый", "Лиловый"]
}

EXPECTED_TRIALS_PER_PARTICIPANT = 80
TRIALS_PER_NODE = 20
REPEAT_TRIALS = 3
nodes = [
    StaticNode(
        definition={**color},
    )
    for color in colors_data
]


class TagControl(Control):
    def __init__(
            self,
            n_tags: 5,
            placeholder: ''
    ):
        super().__init__()
        self.n_tags = n_tags
        self.placeholder = placeholder
        _, _p = get_translator(
            LANGUAGE, module="experiment", locales_dir=os.path.abspath("locales")
        )
        self.alert_no_spaces = _('Color names may not contain spaces.')
        self.alert_no_numbers = _('Color names may not contain numbers.')
        self.alert_no_symbols = _('Color names may not contain symbols other than letters.')

    macro = "tag_control"
    external_template = 'custom_control.html'



class RGBColorPrompt(Prompt):
    """
    Displays a color to the participant.

    Parameters
    ----------

    color
        Color to show, specified as a list of RGB values.

    text
        Text to display to the participant. This can either be a string
        for plain text, or an HTML specification from ``flask.Markup``.

    width
        CSS width specification for the color box (default ``"200px"``).

    height
        CSS height specification for the color box (default ``"200px"``).

    text_align
        CSS alignment of the text.

    """

    def __init__(
            self,
            color: List[float],
            text: Union[str, Markup],
            width: str = "200px",
            height: str = "200px",
            text_align: str = "left",
    ):
        assert isinstance(color, list)
        super().__init__(text=text, text_align=text_align)
        self.rgb = color
        self.width = width
        self.height = height

    macro = "rgb_color"
    external_template = 'custom_prompt.html'

    @property
    def metadata(self):
        return {"text": str(self.text), "rgb": self.rgb}


class ColorTrial(StaticTrial):
    time_estimate = 5

    def show_trial(self, experiment, participant):
        locale = participant.get_locale(experiment)
        color = [self.definition[c] for c in 'rgb']

        _, _p = get_translator(
            locale, module="experiment", locales_dir=os.path.abspath("locales")
        )

        prompt = " ".join([
            _p("prompt", "You will see below a list of 15 basic color names."),
            _p("prompt", "Which of these names best describes the color above?"),
        ])

        labels = random.sample(COLOR_LABELS[locale], len(COLOR_LABELS[locale]))

        return ModularPage(
            "color",
            RGBColorPrompt(color=color, text=prompt),
            PushButtonControl(choices=labels, arrange_vertically=False),
            time_estimate=self.time_estimate,
        )


class ColorTrialMaker(StaticTrialMaker):
    pass


trial_maker = ColorTrialMaker(
    id_="colors_trial_maker",
    trial_class=ColorTrial,
    nodes=nodes,
    max_trials_per_participant=EXPECTED_TRIALS_PER_PARTICIPANT,
    expected_trials_per_participant=EXPECTED_TRIALS_PER_PARTICIPANT,
    allow_repeated_nodes=False,
    balance_across_nodes=True,
    check_performance_at_end=False,
    check_performance_every_trial=False,
    target_trials_per_node=TRIALS_PER_NODE,
    recruit_mode="n_trials",
    n_repeat_trials=REPEAT_TRIALS,
)

def with_translation(function, time_estimate=5):
    def wrapper(participant, experiment):
        _, _p = get_translator(
            participant.get_locale(experiment), module="experiment", locales_dir=os.path.abspath("locales")
        )
        return function(_, _p, time_estimate)

    return PageMaker(
        lambda participant, experiment: wrapper(participant, experiment),
        time_estimate=time_estimate,
    )


def is_color_blind(_, _p, time_estimate):
    return ModularPage(
        "color_blind",
        _("Have you been diagnosed with color blindness?"),
        PushButtonControl(choices=[_("Yes"), _("No")], arrange_vertically=False),
        time_estimate=time_estimate,
    )

def name_colors(_, _p, time_estimate):
    n_tags = 8
    return ModularPage(
        "name_colors",
        " ".join([
            _("Please name at least 8 basic color names."),
            _("Press enter after each color name."),
            _("Only use lower-case letters."),
            ]),
        TagControl(n_tags=n_tags, placeholder=_("Type more color names")),
        time_estimate=time_estimate,
        js_vars={"n_tags": n_tags, "tag_count": _("Number of color names so far: "), 'alert_msg': _("You need to specify at least {N_TAGS} color names to continue.").format(N_TAGS=n_tags)},
    )

def get_instructions(_, _p, time_estimate):
    join(
        InfoPage(
            _p("instructions", "During this experiment, you will be presented with a square of a particular color and will be required to select the most suitable color term from a list of options."),
            time_estimate=time_estimate/2,
        ),
        InfoPage(
            " ".join([
                _p("instructions",
                   "Please be aware that some of the colors may be repeated to verify consistency of your choices."),
                _p("instructions",
                   "If we detect any inconsistencies in your answers, we may terminate the experiment prematurely."),
                _p("instructions",
                   "The best strategy is to answer each question truthfully, as attempting to memorize responses may prove difficult.")
            ]),
            time_estimate=time_estimate/2,
        )
    )

def get_prolific_settings(language):
    with open(
        f"qualifications/prolific/qualification_prolific_{language}.json", "r"
    ) as f:
        qualification = json.dumps(json.load(f))
    return {
        "language": language,
        "recruiter": "prolific",
        "id": f"{language}_color_naming",
        "prolific_reward_cents": 15,
        "prolific_estimated_completion_minutes": 1,
        "prolific_maximum_allowed_minutes": 30,
        "prolific_recruitment_config": qualification,
        "base_payment": 0.0,
        "auto_recruit": False,
        "currency": "£",
    }

def get_title_and_description(language):
    _, _p = get_translator(
        language, module="experiment", locales_dir=os.path.abspath("locales")
    )
    return {
        "title": _p("ad", "Color naming experiment (Chrome browser required, 9 minutes)"),
        "description": (
                _p("ad", "In this experiment you will be presented with a square of a particular color and " +
                "will be required to select the most suitable color term from a list of options.") + " " +
                _p("ad", "The test takes about 9 minutes.") + " " +
                _p("ad", "Please use Chrome browser.") + " " +
                _p("ad", "You will be compensated for the duration of the experiment.")
        )
    }

class Exp(psynet.experiment.Experiment):
    config = {
        'initial_recruitment_size': 20,
        'language': LANGUAGE,
        "docker_image_base_name": "docker.io/polvanrijn/color-en",
        "auto_recruit": False,
        **get_prolific_settings(LANGUAGE),
        **get_title_and_description(LANGUAGE),
        "contact_email_on_error": "computational.audition+online_running_pol@gmail.com",
        "organization_name": "Max Planck Institute for Empirical Aesthetics",
    }

    variable_placeholders = {
        "N_TAGS": 8,
    }

    timeline = Timeline(
        MainConsent(),
        with_translation(get_instructions, time_estimate=6),
        with_translation(name_colors, time_estimate=40),
        trial_maker,
        switch(
            "color_blind_switch",
            lambda participant, experiment: participant.get_locale(experiment),
            {
                locale: ColorBlindnessTest(performance_threshold=0, locale=locale)
                for locale in SUPPORTED_LANGUAGES
            },
            fix_time_credit=False
        ),
        with_translation(is_color_blind, time_estimate=6),
        SuccessfulEndPage(),
    )
