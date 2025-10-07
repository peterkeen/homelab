$(function() {
  
  $('.exp-date').payment('formatCardExpiry');
  $('input[data-stripe="number"]').payment('formatCardNumber');
  $('input[data-stripe="cvc"]').payment('formatCardCVC');

  $('.card-number').on('keyup', function() {
    var e = $('.card-number').first();
    var type = $.payment.cardType(e.val());
    var img = "card.png";
    switch(type) {
        case "visa":
          img = "visa.png";
          break;
        case "mastercard":
          img = "mastercard.png";
          break;
        case "discover":
          img = "discover.png";
          break;
        case "amex":
          img = "amex.png";
          break;
    }
    e.css('background-image', 'url(/images/' + img + ')');
  });
  
  $('.exp-date').on('keyup', function() {
      var e = $('.exp-date').first();
      var out = $.payment.cardExpiryVal(e.val());
      $('input[data-stripe="exp_month"]').val(out.month);
      $('input[data-stripe="exp_year"]').val(out.year);
  });
});
