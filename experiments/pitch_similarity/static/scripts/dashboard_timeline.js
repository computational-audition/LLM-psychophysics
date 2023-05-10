$(document).ready(function() {
  $('.chart.spending').append(
    '<div class="progress spending" style="cursor: pointer;" title="Click to toggle spending limits control" data-html="true">' +
      '<div class="progress-bar spending" aria-valuenow="60" aria-valuemin="0" aria-valuemax="100" style="width: 0%;">' +
        '<span class="show spending">···</span>' +
      '</div>' +
    '</div>'
  );
  $.each(timelineModules["modules"], function() {
    $('.chart.modules').append(
      '<div class="progress modules" id="' + this['id'] + '" data-module-id="' + this['id'] + '" data-html="true">' +
        '<div class="progress-bar ' + this['id'] + '" aria-valuenow="60" aria-valuemin="0" aria-valuemax="100" style="width: 0%;">' +
          '<span class="show ' + this['id'] + '">' + this['id'] + '</span>' +
        '</div>' +
      '</div>'
    );
  });

  $('.progress.modules').tooltip();

  $('.progress.modules').click(function(data) {
    updateDetails($(this).data('module-id'));
  });

  $('.progress.spending').click(function() {
    $('#change-spending-limits').toggle();
  });

  $('#update-spending-limits').click(function() {
    let hardMaxExperimentPayment = parseFloat($('#hard-max-experiment-payment').val());
    let softMaxExperimentPayment = parseFloat($('#soft-max-experiment-payment').val());

    if (hardMaxExperimentPayment < softMaxExperimentPayment) {
      alert("The 'Hard maximum spending limit' must be equal or greater than the 'Soft maximum spending limit'.");
    } else {
      postData = {}
      postData['hard_max_experiment_payment'] = hardMaxExperimentPayment;
      postData['soft_max_experiment_payment'] = softMaxExperimentPayment;
      $.post('/module/update_spending_limits', postData);
    }
  });

  var moduleIds = timelineModules["modules"].map(moduleData => moduleData['id']);
  getData = {};
  getData['module_ids'] = moduleIds;

  setInterval(function() {
    $.get('/module/progress_info', getData)
      .done(function(data) {
        // update spending
        let hardMaxExperimentPayment = data['spending']['hard_max_experiment_payment'].toFixed(2);
        let softMaxExperimentPayment = data['spending']['soft_max_experiment_payment'].toFixed(2);
        if ($('#hard-max-experiment-payment').val() == '') {
          $('#hard-max-experiment-payment').val(parseInt(hardMaxExperimentPayment));
        }
        if ($('#soft-max-experiment-payment').val() == '') {
          $('#soft-max-experiment-payment').val(parseInt(softMaxExperimentPayment));
        }
        let amountSpent = (data['spending']['amount_spent']).toFixed(2);
        let spendingPercentage = Number((amountSpent / softMaxExperimentPayment * 100).toFixed(1));
        $('.show.spending').text(spendingPercentage + '% spent: $' + amountSpent + ' of $' + softMaxExperimentPayment + ' (Hard max. limit: $' + hardMaxExperimentPayment + ')');
        let status = '';
        if (spendingPercentage >= 80 && spendingPercentage < 90) {
          status = 'scarce';
        } else if (spendingPercentage >= 90) {
          status = 'very-scarce';
        }
        $('.progress-bar.spending').css('width', spendingPercentage + '%').addClass(status);
        $('.progress.spending').addClass(status);

        // update progress
        $.each(moduleIds, function(index, moduleId) {
          let hasTarget = data[moduleId]['target_num_participants'] ? true : false
          let progressPercentage = Number((data[moduleId]['progress'] * 100).toFixed(3));
          let text = moduleId + ': ' + data[moduleId]['started_num_participants'] + '/' + data[moduleId]['finished_num_participants'] + '/' + data[moduleId]['aborted_num_participants'] + (hasTarget ? '/' + data[moduleId]['target_num_participants'] : '') + ' (started/finished/aborted' + (hasTarget ? '/target) ' + progressPercentage + '%' : ')')
          $('.show.' + moduleId).text(text);
          if (data[moduleId]['finished_num_participants'] > 0) {
            $('.progress-bar.' + moduleId).css('width', progressPercentage + '%');
          }
        });
      });
  }, 2000);

  $('.progress.modules').mouseenter(function(data) {
    updateTooltip($(this).data('module-id'));
  });

  $('#hard-max-experiment-payment-tooltip-link').mouseover(function() {
    var posX = $(this).offset().left;
    var posY = $(this).offset().top;
    showOptionsTooltip('hard-max-experiment-payment', posX, posY);
  });
  $('#hard-max-experiment-payment-tooltip-link').mouseout(function() {
    hideOptionsTooltip('hard-max-experiment-payment');
  });

  $('#soft-max-experiment-payment-tooltip-link').mouseover(function() {
    var posX = $(this).offset().left;
    var posY = $(this).offset().top;
    showOptionsTooltip('soft-max-experiment-payment', posX, posY);
  });
  $('#soft-max-experiment-payment-tooltip-link').mouseout(function() {
    hideOptionsTooltip('soft-max-experiment-payment');
  });
});

function showOptionsTooltip(param, posX, posY) {
  var tooltip = $('#' + param + '-tooltip');
  tooltip.css('left', posX - 358);
  tooltip.css('top', posY + 60);
  tooltip.show();
}

function hideOptionsTooltip(param) {
  $('#' + param + '-tooltip').hide();
}

function updateDetails(moduleId) {
  $("#element-details").load('/module', { 'moduleId': moduleId });
}

function updateTooltip(moduleId) {
  $.post('/module/tooltip', { 'moduleId': moduleId }, function(data) {
    let selector = 'div[id="' + moduleId + '"].progress';
    if ($(selector + ':hover').length != 0) {
      $(selector).tooltip('dispose').tooltip({title: data}).tooltip('show');
    } else {
      $(selector).tooltip('dispose');
    }
  });
}
