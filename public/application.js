$(document).ready(function() {
  player_hits();
  player_stays();
  dealer();
});



function player_hits() { 
  $(document).on("click", "form#hit-form input", function(){
    $.ajax({
      type: "POST",
      url: "/game/player/hit"
    }).done(function(msg) {
        $("#game").replaceWith(msg);
        $("#welcome").hide();
      });
    return false;
  });
};

function player_stays() { 
  $(document).on("click", "form#stay-form input", function(){
    $.ajax({
      type: "POST",
      url: '/game/player/stay'
    }).done(function(msg) {
        $("#game").replaceWith(msg);
        $("#welcome").hide();
      });
    return false;
  });
};

function dealer() { 
  $(document).on("click", "form#dealer-btn input", function(){
    $.ajax({
      type: "POST",
      url: "/game/dealer"
    }).done(function(msg) {
        $("#game").replaceWith(msg);
        $("#welcome").hide();
      });
    return false;
  });
};
