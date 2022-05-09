$(document).ready(function(){
    $('Deposit::STUDENT_OPTIONS').on('change', function() {
      if ( this.value === 'Yes')
      //.....................^.......
      {
        $("#student_info").show();
      }
      else
      {
        $("#student_info").hide();
      }
    });
});