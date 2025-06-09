class CustomerAddress {
  constructor() {
    this.initCustomerAddress();
    this.customerAddressSelector();
    this.initDeleteAddressButtons();
  }

  initDeleteAddressButtons(){
    const deleteButtons = document.querySelectorAll("button[data-delete-address]");
    if (deleteButtons.length < 1) return;
    deleteButtons.forEach(button => {
        button.addEventListener("click", function(e) {
            var url = this.dataset.url;

            let confirmation = confirm("Are you sure you want to delete this address?");
            if (!confirmation) return;

            document.querySelector(`form[action="${url}"]`).submit();
        })
    })
  }

  initCustomerAddress() {
    const allAddressSelector = document.querySelectorAll("select[data-country-selector]");
    if (allAddressSelector.length < 1) return;

    allAddressSelector.forEach(select => {
      const selectedCountry = this.getSelectedCountry(select);
      if (!selectedCountry) return;

      let province = selectedCountry.dataset.provinces;
      let arrayOfProvinces = JSON.parse(province);
      let provinceSelector = document.querySelector(`#address_province_${select.dataset.id}`);

      if (arrayOfProvinces.length < 1) {
        provinceSelector.setAttribute('disabled', 'disabled');
      } else {
        provinceSelector.removeAttribute('disabled');
      }

      provinceSelector.innerHTML = '';
      let options = '';
      for (let index = 0; index < arrayOfProvinces.length; index++) {
        if (arrayOfProvinces[index][0] === provinceSelector.getAttribute('value')) {
          options += `<option value="${arrayOfProvinces[index][0]}" selected="selected">${arrayOfProvinces[index][0]}</option>`;
        } else {
          options += `<option value="${arrayOfProvinces[index][0]}">${arrayOfProvinces[index][0]}</option>`;
        }
      }

      provinceSelector.innerHTML = options;
    });
  }

  getSelectedCountry(select) {
    let option, selectedOption;
    for (let index = 0; index < select.options.length; index++) {
      option = select.options[index];
      if (option.value === select.getAttribute('value')) {
        selectedOption = option;
        selectedOption.setAttribute('selected', 'selected');
        break;
      }
    }
    return selectedOption;
  }

  customerAddressSelector() {
    const addressSelector = document.querySelectorAll("select[data-country-selector]");
    if (addressSelector.length < 1) return;

    addressSelector.forEach(select => {
      select.addEventListener('change', function(e) {
        let provinces = this.options[this.selectedIndex].dataset.provinces;
        let arrayOfProvinces = JSON.parse(provinces);
        let provinceSelector = document.querySelector(`#address_province_${this.dataset.id}`);

        if (arrayOfProvinces.length < 1) {
          provinceSelector.setAttribute('disabled', 'disabled');
        } else {
          provinceSelector.removeAttribute('disabled');
        }

        provinceSelector.innerHTML = '';
        let options = '';
        for (let index = 0; index < arrayOfProvinces.length; index++) {
          options += `<option value="${arrayOfProvinces[index][0]}">${arrayOfProvinces[index][0]}</option>`;
        }

        provinceSelector.innerHTML = options;
      });
    });
  }
}

// Initialize the customer address functionality
window.addEventListener('DOMContentLoaded', () => {
  new CustomerAddress();
});
