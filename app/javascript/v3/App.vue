<script>
import SnackbarContainer from './components/SnackBar/Container.vue';
import {
  hexToRgbSpace,
  generateThemeVariables,
  isDarkBackground,
} from 'dashboard/helper/colorHelper';

export default {
  components: { SnackbarContainer },
  data() {
    return { theme: 'light' };
  },
  mounted() {
    this.setColorTheme();
    this.listenToThemeChanges();
    this.setLocale(window.chatwootConfig.selectedLocale);
    // Apply brand colors from server-injected globalConfig (for custom domain branding on login page)
    if (window.globalConfig && window.globalConfig.BRAND_COLORS) {
      this.applyBrandColors(window.globalConfig.BRAND_COLORS);
    }
  },
  methods: {
    setColorTheme() {
      const hasDomainBranding =
        window.globalConfig && window.globalConfig.BRAND_COLORS;
      const isBrandDark =
        hasDomainBranding &&
        window.globalConfig.BRAND_COLORS.background &&
        isDarkBackground(window.globalConfig.BRAND_COLORS.background);

      if (
        isBrandDark ||
        window.matchMedia('(prefers-color-scheme: dark)').matches
      ) {
        this.theme = 'dark';
        document.documentElement.classList.add('dark');
        document.body.classList.add('dark');
      } else {
        this.theme = 'light';
        document.documentElement.classList.remove('dark');
        document.body.classList.remove('dark');
      }
    },
    listenToThemeChanges() {
      const mql = window.matchMedia('(prefers-color-scheme: dark)');

      mql.onchange = e => {
        const hasDomainBranding =
          window.globalConfig && window.globalConfig.BRAND_COLORS;
        const isBrandDark =
          hasDomainBranding &&
          window.globalConfig.BRAND_COLORS.background &&
          isDarkBackground(window.globalConfig.BRAND_COLORS.background);

        if (isBrandDark || e.matches) {
          this.theme = 'dark';
          document.documentElement.classList.add('dark');
          document.body.classList.add('dark');
        } else {
          this.theme = 'light';
          document.documentElement.classList.remove('dark');
          document.body.classList.remove('dark');
        }
      };
    },
    setLocale(locale) {
      if (locale) {
        this.$root.$i18n.locale = locale;
      }
    },
    applyBrandColors(colors) {
      if (!colors) return;
      const { primary, text, background } = colors;

      if (primary) {
        const primaryRgb = hexToRgbSpace(primary);
        if (primaryRgb) {
          document.documentElement.style.setProperty(
            '--woot-brand',
            primaryRgb
          );
        }
      }

      if (text) {
        const textRgb = hexToRgbSpace(text);
        if (textRgb) {
          document.documentElement.style.setProperty('--slate-12', textRgb);
        }
      }

      if (background) {
        const themeVars = generateThemeVariables(background);
        if (themeVars) {
          Object.entries(themeVars).forEach(([key, value]) => {
            if (value) document.documentElement.style.setProperty(key, value);
          });
        }
      }
    },
  },
};
</script>

<template>
  <div class="h-full min-h-screen w-full antialiased" :class="theme">
    <router-view />
    <SnackbarContainer />
  </div>
</template>

<style lang="scss">
@tailwind base;
@tailwind components;
@tailwind utilities;

@import '../dashboard/assets/scss/next-colors';

html,
body {
  font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto,
    Oxygen-Sans, Ubuntu, Cantarell, 'Helvetica Neue', sans-serif;
  @apply h-full w-full;

  input,
  select {
    outline: none;
  }
}

.text-link {
  @apply text-n-brand font-medium hover:text-n-blue-10;
}

.v-popper--theme-tooltip .v-popper__inner {
  background: black !important;
  font-size: 0.75rem;
  padding: 4px 8px !important;
  border-radius: 6px;
  font-weight: 400;
}

.v-popper--theme-tooltip .v-popper__arrow-container {
  display: none;
}
</style>
