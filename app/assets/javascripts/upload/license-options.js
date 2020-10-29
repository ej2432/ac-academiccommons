// Change license options based on the copyright status that is selected.

$(document).ready(function(){
  function addLicenseDropdown(div, licenses, prompt) {
    var s = $('<select skip_default_ids="false" allow_method_names_outside_object="true" name="deposit[license]" id="deposit_license">');

    if (prompt != undefined) {
      $('<option/>', { text: prompt }).appendTo(s)
    }

    var hiddenInput = $('input[type="hidden"][name="deposit[license]"]')

    for (i = 0; i < licenses.length; ++i) {
      option = $('<option />', {
        value: licenses[i].value,
        text: licenses[i].text,
        selected: (hiddenInput.attr('value') === licenses[i].value) ? 'selected' : null
      }).appendTo(s);
    }

    s.appendTo(div);
  }

  $('form#upload select#deposit_rights').change(function() {
    var inCopyright = 'http://rightsstatements.org/vocab/InC/1.0/';
    var noCopyright = 'http://rightsstatements.org/vocab/NoC-US/1.0/';

    if ($(this).val() != inCopyright && $(this).val() != noCopyright){
      return;
    }

    var div = $('form#upload div#use-by-others')

    // Remove any previous selection.
    var license_select = $('select[name="deposit[license]"]')
    if (license_select.length) {
      $(license_select).remove();
    }

    // If this label isn't present, add it.
    if ($('label[for=deposit_license]').length == 0) {
      $(div).append($('<div class="animated fadeIn"><label for="deposit_license" class="control-label">Licenses</label><p class="note">Read more at the links below (links open in a new tab) and select your preferred license from the drop-down menu.<ul><li><a href="https://creativecommons.org/licenses/by/4.0/">test</a></p></div>'))
    }

    // Add dropdown with appropriate list of license options depending on
    //copyright selection
    if ( $(this).val() === noCopyright ) {
      var licenses = [{ text: 'CC0', value: 'https://creativecommons.org/publicdomain/zero/1.0/' }];
    } else {
      var licenses = [
        { text: 'Use by others as provided for by copyright laws - All rights reserved', value: '' },
        { text: 'Attribution (CC BY)', value: 'https://creativecommons.org/licenses/by/4.0/' },
        { text: 'Attribution-ShareAlike (CC BY-SA)', value: 'https://creativecommons.org/licenses/by-sa/4.0/' },
        { text: 'Attribution-NoDerivs (CC BY-ND)', value: 'https://creativecommons.org/licenses/by-nd/4.0/' },
        { text: 'Attribution-NonCommercial (CC BY-NC)', value: 'https://creativecommons.org/licenses/by-nc/4.0/' },
        { text:'Attribution-NonCommercial-ShareAlike (CC BY-NC-SA)', value: 'https://creativecommons.org/licenses/by-nc-sa/4.0/'},
        { text: 'Attribution-NonCommercial-NoDerivs (CC BY-NC-ND)', value: 'https://creativecommons.org/licenses/by-nc-nd/4.0/'},
      ];
    }

    addLicenseDropdown(div, licenses);
  }).change();
});
