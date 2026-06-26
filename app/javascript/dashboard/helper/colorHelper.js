import { lighten, darken, getLuminance, toRgba } from 'color2k';

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
  ];
  keys.forEach(key => document.documentElement.style.removeProperty(key));
};
