import { LocalStorage } from 'shared/helpers/localStorage';
import { LOCAL_STORAGE_KEYS } from 'dashboard/constants/localStorage';
import { clearCustomThemeVariables } from './colorHelper';

export const setColorTheme = isOSOnDarkMode => {
  const selectedColorScheme =
    LocalStorage.get(LOCAL_STORAGE_KEYS.COLOR_SCHEME) || 'auto';

  // If we are moving away from custom, ensure inline custom backgrounds are cleared.
  // But skip clearing if BRAND_COLORS are injected by the server (custom domain branding).
  const hasDomainBranding =
    window.globalConfig && window.globalConfig.BRAND_COLORS;
  if (selectedColorScheme !== 'custom' && !hasDomainBranding) {
    clearCustomThemeVariables();
  }

  if (
    (selectedColorScheme === 'auto' && isOSOnDarkMode) ||
    selectedColorScheme === 'dark'
  ) {
    document.body.classList.add('dark');
    document.documentElement.style.setProperty('color-scheme', 'dark');
  } else if (selectedColorScheme !== 'custom') {
    document.body.classList.remove('dark');
    document.documentElement.style.setProperty('color-scheme', 'light');
  }
};
