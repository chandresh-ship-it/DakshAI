import { LocalStorage } from 'shared/helpers/localStorage';
import { LOCAL_STORAGE_KEYS } from 'dashboard/constants/localStorage';
import { clearCustomThemeVariables, isDarkBackground } from './colorHelper';

export const setColorTheme = (isOSOnDarkMode, brandColors) => {
  const selectedColorScheme =
    LocalStorage.get(LOCAL_STORAGE_KEYS.COLOR_SCHEME) || 'auto';

  // If we are moving away from custom, ensure inline custom backgrounds are cleared.
  // But skip clearing if BRAND_COLORS are injected by the server (custom domain branding).
  const hasDomainBranding =
    window.globalConfig && window.globalConfig.BRAND_COLORS;

  const activeBrandColors =
    brandColors ||
    (hasDomainBranding ? window.globalConfig.BRAND_COLORS : null);

  const hasActiveColors =
    activeBrandColors &&
    (activeBrandColors.primary ||
      activeBrandColors.text ||
      activeBrandColors.background);

  // Clear custom variables if the user explicitly selected standard Light or Dark mode,
  // or if there is no brand coloring configured at all.
  if (
    selectedColorScheme === 'light' ||
    selectedColorScheme === 'dark' ||
    (!hasDomainBranding && !hasActiveColors)
  ) {
    clearCustomThemeVariables();
  }

  const isBrandDark =
    activeBrandColors &&
    activeBrandColors.background &&
    isDarkBackground(activeBrandColors.background);

  let isDark =
    (selectedColorScheme === 'auto' && isOSOnDarkMode) ||
    selectedColorScheme === 'dark';

  // For custom theme or auto-theme with active branding, derive dark/light from the brand colors.
  if (selectedColorScheme === 'custom') {
    isDark = !!isBrandDark;
  } else if (selectedColorScheme === 'auto' && (hasDomainBranding || hasActiveColors)) {
    isDark = !!isBrandDark;
  }

  if (isDark) {
    document.body.classList.add('dark');
    document.documentElement.classList.add('dark');
    document.documentElement.style.setProperty('color-scheme', 'dark');
  } else {
    document.body.classList.remove('dark');
    document.documentElement.classList.remove('dark');
    document.documentElement.style.setProperty('color-scheme', 'light');
  }
};
