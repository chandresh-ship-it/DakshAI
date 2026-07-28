import countries from 'shared/constants/countries';

const countryOptions = countries.map(country => ({
  id: country.id,
  label: `${country.emoji} ${country.name} (${country.id})`,
  name: country.name,
}));

const parseCodes = value =>
  value
    .split(/[,\s]+/)
    .map(code => code.trim().toUpperCase())
    .filter(Boolean);

const formatCodes = codes => [...new Set(codes)].join(', ');

const findCountry = code =>
  countryOptions.find(country => country.id === code.toUpperCase());

class PaymentGatewayCountryPicker {
  constructor(root) {
    this.root = root;
    this.hiddenInput = root.querySelector('.js-country-codes-input');
    this.tagsContainer = root.querySelector('.js-country-tags');
    this.searchInput = root.querySelector('.js-country-search');
    this.suggestions = root.querySelector('.js-country-suggestions');
    this.selectedCodes = parseCodes(
      root.dataset.initialCodes || this.hiddenInput?.value || ''
    );

    this.renderTags();
    this.bindEvents();
  }

  bindEvents() {
    this.searchInput.addEventListener('input', () => this.showSuggestions());
    this.searchInput.addEventListener('focus', () => this.showSuggestions());
    this.searchInput.addEventListener('keydown', event => {
      if (event.key === 'Enter') {
        event.preventDefault();
        this.selectFirstSuggestion();
      }
      if (event.key === 'Backspace' && !this.searchInput.value) {
        this.removeCode(this.selectedCodes[this.selectedCodes.length - 1]);
      }
    });

    document.addEventListener('click', event => {
      if (!this.root.contains(event.target)) {
        this.hideSuggestions();
      }
    });
  }

  showSuggestions() {
    const query = this.searchInput.value.trim().toLowerCase();
    const matches = countryOptions
      .filter(country => !this.selectedCodes.includes(country.id))
      .filter(country => {
        if (!query) return true;
        return (
          country.id.toLowerCase().includes(query) ||
          country.name.toLowerCase().includes(query) ||
          country.label.toLowerCase().includes(query)
        );
      })
      .slice(0, 8);

    this.suggestions.innerHTML = '';
    if (!matches.length) {
      this.suggestions.classList.add('hidden');
      return;
    }

    matches.forEach(country => {
      const item = document.createElement('button');
      item.type = 'button';
      item.className =
        'block w-full px-3 py-2 text-left text-sm text-slate-900 hover:bg-violet-50';
      item.textContent = country.label;
      item.addEventListener('click', () => {
        this.addCode(country.id);
        this.searchInput.value = '';
        this.hideSuggestions();
        this.searchInput.focus();
      });
      this.suggestions.appendChild(item);
    });

    this.suggestions.classList.remove('hidden');
  }

  selectFirstSuggestion() {
    const first = this.suggestions.querySelector('button');
    if (first) first.click();
  }

  hideSuggestions() {
    this.suggestions.classList.add('hidden');
  }

  addCode(code) {
    const normalized = code.toUpperCase();
    if (!findCountry(normalized) || this.selectedCodes.includes(normalized)) {
      return;
    }

    this.selectedCodes.push(normalized);
    this.sync();
  }

  removeCode(code) {
    if (!code) return;
    this.selectedCodes = this.selectedCodes.filter(item => item !== code);
    this.sync();
  }

  sync() {
    this.hiddenInput.value = formatCodes(this.selectedCodes);
    this.renderTags();
  }

  renderTags() {
    this.tagsContainer.innerHTML = '';

    if (!this.selectedCodes.length) {
      const empty = document.createElement('span');
      empty.className = 'text-xs text-slate-400';
      empty.textContent = 'Default fallback (all unmatched countries)';
      this.tagsContainer.appendChild(empty);
      return;
    }

    this.selectedCodes.forEach(code => {
      const country = findCountry(code);
      const tag = document.createElement('span');
      tag.className =
        'inline-flex items-center gap-1 rounded-full bg-violet-50 px-2 py-1 text-xs font-medium text-violet-800';

      const label = document.createElement('span');
      label.textContent = country ? country.label : code;

      const removeButton = document.createElement('button');
      removeButton.type = 'button';
      removeButton.className = 'text-violet-600 hover:text-violet-900';
      removeButton.setAttribute('aria-label', `Remove ${code}`);
      removeButton.textContent = '×';
      removeButton.addEventListener('click', () => this.removeCode(code));

      tag.appendChild(label);
      tag.appendChild(removeButton);
      this.tagsContainer.appendChild(tag);
    });
  }
}

document.addEventListener('DOMContentLoaded', () => {
  document
    .querySelectorAll('[data-payment-gateway-countries]')
    .forEach(root => new PaymentGatewayCountryPicker(root));
});
