import { lighten, darken, getLuminance, toRgba, transparentize } from 'color2k';

export const hexToRgbSpace = color => {
  if (!color) return null;
  try {
    const rgba = toRgba(color);
    const result = /^rgba\((\d+),\s*(\d+),\s*(\d+),\s*[^)]+\)$/.exec(rgba);
    if (!result) return null;
    return `${result[1]} ${result[2]} ${result[3]}`;
  } catch {
    return null;
  }
};

export const generateThemeVariables = backgroundHex => {
  if (!backgroundHex) return null;
  const isDark = getLuminance(backgroundHex) < 0.5;
  const vars = {};

  if (isDark) {
    vars['--background-color'] = hexToRgbSpace(backgroundHex);
    vars['--surface-1'] = hexToRgbSpace(lighten(backgroundHex, 0.03));
    vars['--surface-2'] = hexToRgbSpace(lighten(backgroundHex, 0.05));
    vars['--surface-active'] = hexToRgbSpace(lighten(backgroundHex, 0.1));
    vars['--solid-1'] = hexToRgbSpace(lighten(backgroundHex, 0.02));
    vars['--solid-2'] = hexToRgbSpace(lighten(backgroundHex, 0.04));
    vars['--solid-3'] = hexToRgbSpace(lighten(backgroundHex, 0.08));
    vars['--card-color'] = hexToRgbSpace(backgroundHex);
    vars['--border-strong'] = hexToRgbSpace(lighten(backgroundHex, 0.15));
    vars['--border-weak'] = hexToRgbSpace(lighten(backgroundHex, 0.08));
    vars['--label-background'] = hexToRgbSpace(lighten(backgroundHex, 0.04));
  } else {
    vars['--background-color'] = hexToRgbSpace(backgroundHex);
    vars['--surface-1'] = hexToRgbSpace(lighten(backgroundHex, 0.03));
    vars['--surface-2'] = hexToRgbSpace(lighten(backgroundHex, 0.04));
    vars['--surface-active'] = hexToRgbSpace(lighten(backgroundHex, 0.05));
    vars['--solid-1'] = hexToRgbSpace(lighten(backgroundHex, 0.05));
    vars['--solid-2'] = hexToRgbSpace(lighten(backgroundHex, 0.05));
    vars['--solid-3'] = hexToRgbSpace(lighten(backgroundHex, 0.05));
    vars['--card-color'] = hexToRgbSpace(lighten(backgroundHex, 0.03));
    vars['--border-strong'] = hexToRgbSpace(darken(backgroundHex, 0.08));
    vars['--border-weak'] = hexToRgbSpace(darken(backgroundHex, 0.04));
    vars['--label-background'] = hexToRgbSpace(backgroundHex);
  }

  return vars;
};

export const generatePrimaryColorVariables = primaryHex => {
  if (!primaryHex) return null;
  const isDark = getLuminance(primaryHex) < 0.5;
  const vars = {};

  // Base is step 9
  vars['--blue-9'] = hexToRgbSpace(primaryHex);
  vars['--woot-brand'] = hexToRgbSpace(primaryHex);

  // Generate 12 steps
  // (We overwrite --blue-1 to --blue-12 to hijack the primary color scale)
  vars['--blue-1'] = hexToRgbSpace(lighten(primaryHex, 0.45));
  vars['--blue-2'] = hexToRgbSpace(lighten(primaryHex, 0.4));
  vars['--blue-3'] = hexToRgbSpace(lighten(primaryHex, 0.35));
  vars['--blue-4'] = hexToRgbSpace(lighten(primaryHex, 0.3));
  vars['--blue-5'] = hexToRgbSpace(lighten(primaryHex, 0.25));
  vars['--blue-6'] = hexToRgbSpace(lighten(primaryHex, 0.15));
  vars['--blue-7'] = hexToRgbSpace(lighten(primaryHex, 0.1));
  vars['--blue-8'] = hexToRgbSpace(lighten(primaryHex, 0.05));
  vars['--blue-10'] = hexToRgbSpace(darken(primaryHex, 0.05));
  vars['--blue-11'] = hexToRgbSpace(darken(primaryHex, 0.1));
  vars['--blue-12'] = hexToRgbSpace(darken(primaryHex, 0.15));

  // Some specific variables in _next-colors.scss:
  vars['--text-blue'] = isDark ? vars['--blue-1'] : vars['--blue-12'];
  vars['--border-blue-strong'] = vars['--blue-7'];
  vars['--solid-blue'] = vars['--blue-9'];
  vars['--solid-blue-2'] = vars['--blue-10'];
  vars['--border-blue'] = hexToRgbSpace(transparentize(primaryHex, 0.5));

  return vars;
};

export const clearCustomThemeVariables = () => {
  const keys = [
    '--background-color',
    '--surface-1',
    '--surface-2',
    '--surface-active',
    '--solid-1',
    '--solid-2',
    '--solid-3',
    '--card-color',
    '--border-strong',
    '--border-weak',
    '--label-background',
    '--slate-12', // for custom text color
    '--woot-brand',
    '--text-blue',
    '--border-blue-strong',
    '--solid-blue',
    '--solid-blue-2',
    '--border-blue',
    ...Array.from({ length: 12 }, (_, i) => `--blue-${i + 1}`),
  ];
  keys.forEach(key => document.documentElement.style.removeProperty(key));
};

export const isDarkBackground = backgroundHex => {
  if (!backgroundHex) return false;
  try {
    return getLuminance(backgroundHex) < 0.5;
  } catch {
    return false;
  }
};
