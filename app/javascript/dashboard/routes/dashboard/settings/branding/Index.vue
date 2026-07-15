<script setup>
import { ref, computed, watch, nextTick } from 'vue';
import { useStore } from 'vuex';
import { useI18n } from 'vue-i18n';
import { useAccount } from 'dashboard/composables/useAccount';
import { useMapGetter } from 'dashboard/composables/store';
import { useAlert } from 'dashboard/composables';
import AccountAPI from 'dashboard/api/account';
import { LocalStorage } from 'shared/helpers/localStorage';
import { LOCAL_STORAGE_KEYS } from 'dashboard/constants/localStorage';
import { setColorTheme } from 'dashboard/helper/themeHelper';
import { getContrast } from 'color2k';
import {
  generatePrimaryColorVariables,
  generateThemeVariables,
  hexToRgbSpace,
  clearCustomThemeVariables,
} from 'dashboard/helper/colorHelper';
import BaseSettingsHeader from '../components/BaseSettingsHeader.vue';
import SectionLayout from '../account/components/SectionLayout.vue';
import WithLabel from 'v3/components/Form/WithLabel.vue';
import NextInput from 'next/input/Input.vue';
import NextButton from 'dashboard/components-next/button/Button.vue';
import MagicBrandingModal from './components/MagicBrandingModal.vue';

const store = useStore();
const { t } = useI18n();
const { accountId } = useAccount();

const getAccount = useMapGetter('accounts/getAccount');
const uiFlags = useMapGetter('accounts/getUIFlags');
const isUpdating = computed(() => uiFlags.value.isUpdating);

const customDomain = ref('');
const brandName = ref('');
const primaryColor = ref('#1F93FF');
const textColor = ref('#FFFFFF');
const backgroundColor = ref('#1A1E29');
const activeLayout = ref('classic');

const lightLogoInput = ref(null);
const darkLogoInput = ref(null);
const faviconInput = ref(null);

const lightLogoFile = ref(null);
const darkLogoFile = ref(null);
const faviconFile = ref(null);
const isMagicModalOpen = ref(false);

const lightLogoPreview = computed(() => {
  if (lightLogoFile.value)
    return window.URL.createObjectURL(lightLogoFile.value);
  const account = getAccount.value(accountId.value);
  return account?.logo_url || null;
});

const darkLogoPreview = computed(() => {
  if (darkLogoFile.value) return window.URL.createObjectURL(darkLogoFile.value);
  const account = getAccount.value(accountId.value);
  return account?.dark_logo_url || null;
});

const faviconPreview = computed(() => {
  if (faviconFile.value) return window.URL.createObjectURL(faviconFile.value);
  const account = getAccount.value(accountId.value);
  return account?.favicon_url || null;
});

const activeAccount = computed(() => getAccount.value(accountId.value));

const domainStatus = computed(() => {
  return activeAccount.value?.ssl_settings?.cf_status || 'not_configured';
});

const isVerified = computed(() => domainStatus.value === 'active');
const isPending = computed(() =>
  ['pending_validation', 'pending_issuance', 'pending_deployment'].includes(
    domainStatus.value
  )
);
const cnameTarget = computed(() => {
  const hostURL =
    window.chatwootConfig?.hostURL || 'https://domains.chatwoot.com';
  try {
    return new URL(hostURL).hostname;
  } catch (e) {
    return hostURL.replace(/^(https?:\/\/)/, '').replace(/\/$/, '');
  }
});

const txtVerificationRecord = computed(() => {
  return activeAccount.value?.ssl_settings?.cf_verification_body || '';
});

const txtVerificationName = computed(() => {
  if (!customDomain.value) return '';
  return `_cf-custom-hostname.${customDomain.value}`;
});

let isWatcherEnabled = false;

function applyLivePreview() {
  const styleNode = document.getElementById('brand-colors');
  if (styleNode) {
    styleNode.remove();
  }

  if (primaryColor.value) {
    const primaryVars = generatePrimaryColorVariables(primaryColor.value);
    if (primaryVars) {
      Object.entries(primaryVars).forEach(([key, value]) => {
        if (value) document.documentElement.style.setProperty(key, value);
      });
    }
  }

  if (textColor.value) {
    const textRgb = hexToRgbSpace(textColor.value);
    if (textRgb) {
      document.documentElement.style.setProperty('--slate-12', textRgb);
    }
  }

  if (backgroundColor.value) {
    const themeVars = generateThemeVariables(backgroundColor.value);
    if (themeVars) {
      Object.entries(themeVars).forEach(([key, value]) => {
        if (value) document.documentElement.style.setProperty(key, value);
      });
    }
  }
}

const activeTheme = ref(
  LocalStorage.get(LOCAL_STORAGE_KEYS.COLOR_SCHEME) || 'light'
);

const setTheme = theme => {
  activeTheme.value = theme;
  LocalStorage.set(LOCAL_STORAGE_KEYS.COLOR_SCHEME, theme);

  if (theme !== 'custom') {
    clearCustomThemeVariables();
  } else {
    applyLivePreview();
  }

  const isOSOnDarkMode = window.matchMedia(
    '(prefers-color-scheme: dark)'
  ).matches;
  setColorTheme(isOSOnDarkMode, {
    primary: primaryColor.value,
    text: textColor.value,
    background: backgroundColor.value,
  });
  window.dispatchEvent(new CustomEvent('theme-changed'));
};

const initFromAccount = () => {
  if (!activeAccount.value) return;
  isWatcherEnabled = false;
  customDomain.value = activeAccount.value.custom_domain || '';

  const colors = activeAccount.value.custom_attributes?.brand_colors || {};
  primaryColor.value = colors.primary || '#1F93FF';
  textColor.value = colors.text || '#FFFFFF';
  backgroundColor.value = colors.background || '#1A1E29';
  activeLayout.value = colors.layout || 'classic';
  brandName.value = colors.brand_name || '';

  if (colors.primary || colors.text || colors.background) {
    activeTheme.value = 'custom';
  } else {
    const storedTheme =
      LocalStorage.get(LOCAL_STORAGE_KEYS.COLOR_SCHEME) || 'light';
    activeTheme.value = storedTheme === 'custom' ? 'light' : storedTheme;
  }

  nextTick(() => {
    isWatcherEnabled = true;
  });
};

watch(activeAccount, initFromAccount, { immediate: true });

const handleCancel = () => {
  initFromAccount();
  lightLogoFile.value = null;
  darkLogoFile.value = null;
  faviconFile.value = null;
};

const handleSave = async (shouldReload = true, isVerifyAction = false) => {
  try {
    const formData = new FormData();
    if (customDomain.value)
      formData.append('custom_domain', customDomain.value);
    if (isVerifyAction) formData.append('force_verify', 'true');
    if (lightLogoFile.value) formData.append('logo', lightLogoFile.value);
    if (darkLogoFile.value) formData.append('dark_logo', darkLogoFile.value);
    if (faviconFile.value) formData.append('favicon', faviconFile.value);

    // Send brand colors as nested hash
    if (activeTheme.value === 'custom') {
      formData.append('brand_colors[primary]', primaryColor.value);
      formData.append('brand_colors[text]', textColor.value);
      formData.append('brand_colors[background]', backgroundColor.value);
    } else {
      formData.append('brand_colors[primary]', '');
      formData.append('brand_colors[text]', '');
      formData.append('brand_colors[background]', '');
    }
    formData.append('brand_colors[layout]', activeLayout.value);
    formData.append('brand_colors[brand_name]', brandName.value);

    store.commit('accounts/SET_ACCOUNT_UI_FLAG', { isUpdating: true });
    const response = await AccountAPI.update(formData);

    // Set localStorage BEFORE committing to Vuex, so that when
    // App.vue's accountBrandColors watcher fires synchronously,
    // it reads the correct color_scheme from localStorage.
    LocalStorage.set(LOCAL_STORAGE_KEYS.COLOR_SCHEME, activeTheme.value);

    store.commit('accounts/EDIT_ACCOUNT', response.data);
    lightLogoFile.value = null;
    darkLogoFile.value = null;
    faviconFile.value = null;
    store.commit('accounts/SET_ACCOUNT_UI_FLAG', { isUpdating: false });

    // Re-apply colors after the store commit to ensure CSS vars survive
    // any watcher cascade that may have cleared them.
    const isOSOnDarkMode = window.matchMedia(
      '(prefers-color-scheme: dark)'
    ).matches;
    const savedColors = {
      primary: primaryColor.value,
      text: textColor.value,
      background: backgroundColor.value,
    };
    if (activeTheme.value === 'custom') {
      applyLivePreview();
    }
    setColorTheme(isOSOnDarkMode, savedColors);

    useAlert(t('BRANDING_SETTINGS.SAVE_SUCCESS'));

    if (shouldReload) {
      window.dispatchEvent(new CustomEvent('theme-changed'));
    }
  } catch {
    store.commit('accounts/SET_ACCOUNT_UI_FLAG', { isUpdating: false });
    useAlert(t('BRANDING_SETTINGS.SAVE_ERROR'));
  }
};

const handleVerify = () => {
  handleSave(false, true);
};

const onLightLogoChange = event => {
  const [file] = event.target.files;
  if (file) lightLogoFile.value = file;
};

const onDarkLogoChange = event => {
  const [file] = event.target.files;
  if (file) darkLogoFile.value = file;
};

const onFaviconChange = event => {
  const [file] = event.target.files;
  if (file) faviconFile.value = file;
};

const hasLowContrast = computed(() => {
  try {
    const textBgContrast = getContrast(textColor.value, backgroundColor.value);
    const primaryBgContrast = getContrast(
      primaryColor.value,
      backgroundColor.value
    );
    return textBgContrast < 4.5 || primaryBgContrast < 3.0;
  } catch {
    return false;
  }
});

const buttonTextColor = computed(() => {
  try {
    const whiteContrast = getContrast(primaryColor.value, '#FFFFFF');
    const blackContrast = getContrast(primaryColor.value, '#000000');
    return blackContrast > whiteContrast ? '#000000' : '#FFFFFF';
  } catch {
    return '#FFFFFF';
  }
});

watch(
  [primaryColor, textColor, backgroundColor],
  () => {
    if (!isWatcherEnabled) return;
    if (activeTheme.value !== 'custom') {
      setTheme('custom');
    }
    applyLivePreview();
  },
  { deep: true }
);

const handleMagicPaletteApplied = palette => {
  if (palette.primary) primaryColor.value = palette.primary;
  if (palette.text) textColor.value = palette.text;
  if (palette.background) backgroundColor.value = palette.background;
};
</script>

<template>
  <div class="grid max-w-2xl ltr:mr-auto rtl:ml-auto">
    <BaseSettingsHeader
      :title="$t('BRANDING_SETTINGS.TITLE')"
      :description="$t('BRANDING_SETTINGS.DESCRIPTION')"
      feature-name="branding"
    />

    <div class="flex flex-col w-full mt-3">
      <div class="flex flex-col w-full max-w-2xl">
        <!-- Custom Domain -->
        <SectionLayout
          :title="$t('BRANDING_SETTINGS.CUSTOM_DOMAIN.TITLE')"
          :description="$t('BRANDING_SETTINGS.CUSTOM_DOMAIN.DESCRIPTION')"
          class="!pt-0"
        >
          <WithLabel name="custom-domain">
            <div class="flex items-center gap-3 w-full">
              <NextInput
                v-model="customDomain"
                type="text"
                class="flex-1 min-w-0"
                :placeholder="$t('BRANDING_SETTINGS.CUSTOM_DOMAIN.PLACEHOLDER')"
              />
              <NextButton
                type="button"
                class="shrink-0"
                blue
                @click="handleVerify"
              >
                {{ $t('BRANDING_SETTINGS.CUSTOM_DOMAIN.VERIFY') }}
              </NextButton>
              <span
                v-if="isVerified"
                class="text-emerald-500 font-semibold text-sm shrink-0"
              >
                {{ $t('BRANDING_SETTINGS.CUSTOM_DOMAIN.VERIFIED') }}
              </span>
              <span
                v-else-if="customDomain && isPending"
                class="text-amber-500 font-semibold text-sm shrink-0"
              >
                {{ $t('BRANDING_SETTINGS.CUSTOM_DOMAIN.PENDING') }}
              </span>
            </div>

            <p class="text-xs text-n-slate-11 mt-3">
              {{ $t('BRANDING_SETTINGS.CUSTOM_DOMAIN.AUTO_CONNECT_LABEL') }}
            </p>
          </WithLabel>

          <div
            v-if="customDomain && !isVerified"
            class="mt-3 flex flex-col gap-5 p-4 bg-n-surface-2 border border-n-strong rounded-xl"
          >
            <!-- Option 1: CNAME -->
            <div class="flex flex-col gap-3">
              <p class="text-xs text-n-slate-12 font-semibold">
                {{ $t('BRANDING_SETTINGS.CUSTOM_DOMAIN.OPTION_1_TITLE') }}
              </p>
              <p class="text-xs text-n-slate-11">
                {{ $t('BRANDING_SETTINGS.CUSTOM_DOMAIN.CNAME_INSTRUCTION') }}
              </p>
              <div
                class="grid grid-cols-[80px,1fr] gap-x-4 gap-y-2 text-xs p-3 bg-n-surface-1 rounded-lg border border-n-strong"
              >
                <span class="text-n-slate-10">{{
                  $t('BRANDING_SETTINGS.CUSTOM_DOMAIN.TYPE')
                }}</span>
                <span class="font-mono text-n-slate-12 font-semibold">{{
                  'CNAME'
                }}</span>

                <span class="text-n-slate-10">{{
                  $t('BRANDING_SETTINGS.CUSTOM_DOMAIN.NAME')
                }}</span>
                <code
                  class="font-mono text-n-slate-12 font-semibold bg-transparent p-0 select-all"
                  >{{ customDomain }}</code
                >

                <span class="text-n-slate-10">{{
                  $t('BRANDING_SETTINGS.CUSTOM_DOMAIN.TARGET')
                }}</span>
                <code
                  class="font-mono text-n-slate-12 font-semibold bg-transparent p-0 select-all"
                  >{{ cnameTarget }}</code
                >
              </div>
            </div>

            <hr v-if="txtVerificationRecord" class="border-n-strong" />

            <!-- Option 2: TXT -->
            <div v-if="txtVerificationRecord" class="flex flex-col gap-3">
              <p class="text-xs text-n-slate-12 font-semibold">
                {{ $t('BRANDING_SETTINGS.CUSTOM_DOMAIN.OPTION_2_TITLE') }}
              </p>
              <p class="text-xs text-n-slate-11">
                {{ $t('BRANDING_SETTINGS.CUSTOM_DOMAIN.TXT_INSTRUCTION') }}
              </p>
              <div
                class="grid grid-cols-[80px,1fr] gap-x-4 gap-y-2 text-xs p-3 bg-n-surface-1 rounded-lg border border-n-strong"
              >
                <span class="text-n-slate-10">{{
                  $t('BRANDING_SETTINGS.CUSTOM_DOMAIN.TYPE')
                }}</span>
                <span class="font-mono text-n-slate-12 font-semibold">{{
                  'TXT'
                }}</span>

                <span class="text-n-slate-10">{{
                  $t('BRANDING_SETTINGS.CUSTOM_DOMAIN.NAME')
                }}</span>
                <code
                  class="font-mono text-n-slate-12 font-semibold bg-transparent p-0 select-all"
                  >{{ txtVerificationName }}</code
                >

                <span class="text-n-slate-10">{{
                  $t('BRANDING_SETTINGS.CUSTOM_DOMAIN.VALUE')
                }}</span>
                <code
                  class="font-mono text-n-slate-12 font-semibold bg-transparent p-0 select-all"
                  >{{ txtVerificationRecord }}</code
                >
              </div>
            </div>
          </div>
        </SectionLayout>

        <!-- Brand Name -->
        <SectionLayout
          with-border
          :title="$t('BRANDING_SETTINGS.BRAND_NAME.TITLE')"
          :description="$t('BRANDING_SETTINGS.BRAND_NAME.DESCRIPTION')"
        >
          <WithLabel name="brand-name">
            <NextInput
              v-model="brandName"
              type="text"
              class="w-full"
              :placeholder="$t('BRANDING_SETTINGS.BRAND_NAME.PLACEHOLDER')"
            />
          </WithLabel>
        </SectionLayout>

        <!-- Logo Upload -->
        <SectionLayout
          with-border
          :title="$t('BRANDING_SETTINGS.LOGO_SETTINGS.TITLE')"
          :description="$t('BRANDING_SETTINGS.LOGO_SETTINGS.DESCRIPTION')"
        >
          <div class="grid grid-cols-1 sm:grid-cols-3 gap-6">
            <!-- Light Logo -->
            <div
              class="flex flex-col items-center p-4 border border-dashed border-n-strong rounded-xl bg-n-surface-2 text-center"
            >
              <span class="text-sm font-semibold text-n-slate-12 mb-1">
                {{ $t('BRANDING_SETTINGS.LOGO_SETTINGS.LIGHT_LOGO.TITLE') }}
              </span>
              <span class="text-xs text-n-slate-11 mb-4">
                {{ $t('BRANDING_SETTINGS.LOGO_SETTINGS.LIGHT_LOGO.NOTE') }}
              </span>
              <div
                class="w-16 h-16 rounded-lg bg-white border border-n-strong flex items-center justify-center mb-4 overflow-hidden"
              >
                <img
                  v-if="lightLogoPreview"
                  :src="lightLogoPreview"
                  class="w-full h-full object-contain"
                  :alt="$t('BRANDING_SETTINGS.LOGO_SETTINGS.LIGHT_LOGO.TITLE')"
                />
                <span v-else class="i-lucide-image text-slate-400 size-6" />
              </div>
              <div class="flex flex-col gap-2 w-full">
                <input
                  ref="lightLogoInput"
                  type="file"
                  accept="image/*"
                  class="hidden"
                  @change="onLightLogoChange"
                />
                <NextButton
                  class="w-full"
                  blue
                  size="small"
                  type="button"
                  @click="lightLogoInput.click()"
                >
                  {{
                    lightLogoFile
                      ? lightLogoFile.name
                      : $t('BRANDING_SETTINGS.LOGO_SETTINGS.CHOOSE_FILE')
                  }}
                </NextButton>
                <span class="text-xs text-n-slate-11">
                  {{ $t('BRANDING_SETTINGS.LOGO_SETTINGS.LIGHT_LOGO.LIMIT') }}
                </span>
              </div>
            </div>

            <!-- Dark Logo -->
            <div
              class="flex flex-col items-center p-4 border border-dashed border-n-strong rounded-xl bg-n-surface-2 text-center"
            >
              <span class="text-sm font-semibold text-n-slate-12 mb-1">
                {{ $t('BRANDING_SETTINGS.LOGO_SETTINGS.DARK_LOGO.TITLE') }}
              </span>
              <span class="text-xs text-n-slate-11 mb-4">
                {{ $t('BRANDING_SETTINGS.LOGO_SETTINGS.DARK_LOGO.NOTE') }}
              </span>
              <div
                class="w-16 h-16 rounded-lg bg-n-surface-1 border border-n-strong flex items-center justify-center mb-4 overflow-hidden"
              >
                <img
                  v-if="darkLogoPreview"
                  :src="darkLogoPreview"
                  class="w-full h-full object-contain"
                  :alt="$t('BRANDING_SETTINGS.LOGO_SETTINGS.DARK_LOGO.TITLE')"
                />
                <span v-else class="i-lucide-image text-slate-400 size-6" />
              </div>
              <div class="flex flex-col gap-2 w-full">
                <input
                  ref="darkLogoInput"
                  type="file"
                  accept="image/*"
                  class="hidden"
                  @change="onDarkLogoChange"
                />
                <NextButton
                  class="w-full"
                  blue
                  size="small"
                  type="button"
                  @click="darkLogoInput.click()"
                >
                  {{
                    darkLogoFile
                      ? darkLogoFile.name
                      : $t('BRANDING_SETTINGS.LOGO_SETTINGS.CHOOSE_FILE')
                  }}
                </NextButton>
                <span class="text-xs text-n-slate-11">
                  {{ $t('BRANDING_SETTINGS.LOGO_SETTINGS.DARK_LOGO.LIMIT') }}
                </span>
              </div>
            </div>

            <!-- Favicon -->
            <div
              class="flex flex-col items-center p-4 border border-dashed border-n-strong rounded-xl bg-n-surface-2 text-center"
            >
              <span class="text-sm font-semibold text-n-slate-12 mb-1">
                {{ $t('BRANDING_SETTINGS.LOGO_SETTINGS.FAVICON.TITLE') }}
              </span>
              <span class="text-xs text-n-slate-11 mb-4">
                {{ $t('BRANDING_SETTINGS.LOGO_SETTINGS.FAVICON.NOTE') }}
              </span>
              <div
                class="w-16 h-16 rounded-lg bg-n-surface-1 border border-n-strong flex items-center justify-center mb-4 overflow-hidden"
              >
                <img
                  v-if="faviconPreview"
                  :src="faviconPreview"
                  class="w-full h-full object-contain"
                  :alt="$t('BRANDING_SETTINGS.LOGO_SETTINGS.FAVICON.TITLE')"
                />
                <span v-else class="i-lucide-globe text-n-slate-11 size-6" />
              </div>
              <div class="flex flex-col gap-2 w-full">
                <input
                  ref="faviconInput"
                  type="file"
                  accept="image/x-icon,image/png,image/svg+xml"
                  class="hidden"
                  @change="onFaviconChange"
                />
                <NextButton
                  class="w-full"
                  blue
                  size="small"
                  type="button"
                  @click="faviconInput.click()"
                >
                  {{
                    faviconFile
                      ? faviconFile.name
                      : $t('BRANDING_SETTINGS.LOGO_SETTINGS.CHOOSE_FILE')
                  }}
                </NextButton>
                <span class="text-xs text-n-slate-11">
                  {{ $t('BRANDING_SETTINGS.LOGO_SETTINGS.FAVICON.LIMIT') }}
                </span>
              </div>
            </div>
          </div>
        </SectionLayout>

        <!-- Appearance Settings -->
        <SectionLayout
          with-border
          :title="$t('BRANDING_SETTINGS.THEME_SETTINGS.TITLE')"
          :description="$t('BRANDING_SETTINGS.THEME_SETTINGS.DESCRIPTION')"
        >
          <div class="grid grid-cols-1 sm:grid-cols-3 gap-4">
            <!-- Light -->
            <button
              type="button"
              class="flex flex-col items-center p-4 border rounded-xl bg-n-surface-2 hover:bg-n-surface-3 transition-all text-center cursor-pointer"
              :class="
                activeTheme === 'light'
                  ? 'border-n-brand ring-2 ring-n-brand/20'
                  : 'border-n-strong'
              "
              @click="setTheme('light')"
            >
              <span class="i-lucide-sun text-amber-500 size-6 mb-2" />
              <span class="text-sm font-semibold text-n-slate-12">
                {{ $t('BRANDING_SETTINGS.THEME_SETTINGS.LIGHT.TITLE') }}
              </span>
              <span class="text-xs text-n-slate-11 mt-1">
                {{ $t('BRANDING_SETTINGS.THEME_SETTINGS.LIGHT.DESCRIPTION') }}
              </span>
            </button>

            <!-- Dark -->
            <button
              type="button"
              class="flex flex-col items-center p-4 border rounded-xl bg-n-surface-2 hover:bg-n-surface-3 transition-all text-center cursor-pointer"
              :class="
                activeTheme === 'dark'
                  ? 'border-n-brand ring-2 ring-n-brand/20'
                  : 'border-n-strong'
              "
              @click="setTheme('dark')"
            >
              <span class="i-lucide-moon text-blue-500 size-6 mb-2" />
              <span class="text-sm font-semibold text-n-slate-12">
                {{ $t('BRANDING_SETTINGS.THEME_SETTINGS.DARK.TITLE') }}
              </span>
              <span class="text-xs text-n-slate-11 mt-1">
                {{ $t('BRANDING_SETTINGS.THEME_SETTINGS.DARK.DESCRIPTION') }}
              </span>
            </button>

            <!-- Custom -->
            <button
              type="button"
              class="flex flex-col items-center p-4 border rounded-xl bg-n-surface-2 hover:bg-n-surface-3 transition-all text-center cursor-pointer"
              :class="
                activeTheme === 'custom'
                  ? 'border-n-brand ring-2 ring-n-brand/20'
                  : 'border-n-strong'
              "
              @click="setTheme('custom')"
            >
              <span class="i-lucide-palette text-emerald-500 size-6 mb-2" />
              <span class="text-sm font-semibold text-n-slate-12">
                {{ $t('BRANDING_SETTINGS.THEME_SETTINGS.CUSTOM.TITLE') }}
              </span>
              <span class="text-xs text-n-slate-11 mt-1">
                {{ $t('BRANDING_SETTINGS.THEME_SETTINGS.CUSTOM.DESCRIPTION') }}
              </span>
            </button>
          </div>
        </SectionLayout>

        <!-- Color Customization -->
        <SectionLayout
          v-if="activeTheme === 'custom'"
          with-border
          :title="$t('BRANDING_SETTINGS.COLOR_SETTINGS.TITLE')"
          :description="$t('BRANDING_SETTINGS.COLOR_SETTINGS.DESCRIPTION')"
        >
          <template #headerActions>
            <NextButton
              type="button"
              blue
              size="small"
              class="w-full sm:w-auto mt-2 sm:mt-0"
              @click="isMagicModalOpen = true"
            >
              <span class="i-lucide-sparkles size-4" />
              {{ $t('BRANDING_SETTINGS.MAGIC_AI.BUTTON') }}
            </NextButton>
          </template>

          <div
            v-if="hasLowContrast"
            class="flex gap-2.5 items-start p-3 bg-amber-500/10 border border-amber-500/30 rounded-xl text-amber-500 text-xs mb-4"
          >
            <span class="i-lucide-alert-triangle size-4 shrink-0 mt-0.5" />
            <p class="leading-relaxed">
              {{ $t('BRANDING_SETTINGS.COLOR_SETTINGS.LOW_CONTRAST_WARNING') }}
            </p>
          </div>

          <div class="grid grid-cols-1 md:grid-cols-2 gap-6 items-start">
            <div class="flex flex-col gap-4">
              <div
                class="flex items-center justify-between p-3 border border-n-strong rounded-xl bg-n-surface-2"
              >
                <span class="text-sm font-semibold text-n-slate-12">
                  {{ $t('BRANDING_SETTINGS.COLOR_SETTINGS.PRIMARY') }}
                </span>
                <div class="flex items-center gap-2">
                  <input
                    v-model="primaryColor"
                    type="color"
                    class="w-8 h-8 rounded cursor-pointer border border-n-strong bg-transparent"
                  />
                  <span
                    class="text-xs font-mono text-n-slate-11 select-all uppercase"
                  >
                    {{ primaryColor }}
                  </span>
                </div>
              </div>

              <div
                class="flex items-center justify-between p-3 border border-n-strong rounded-xl bg-n-surface-2"
              >
                <span class="text-sm font-semibold text-n-slate-12">
                  {{ $t('BRANDING_SETTINGS.COLOR_SETTINGS.TEXT') }}
                </span>
                <div class="flex items-center gap-2">
                  <input
                    v-model="textColor"
                    type="color"
                    class="w-8 h-8 rounded cursor-pointer border border-n-strong bg-transparent"
                  />
                  <span
                    class="text-xs font-mono text-n-slate-11 select-all uppercase"
                  >
                    {{ textColor }}
                  </span>
                </div>
              </div>

              <div
                class="flex items-center justify-between p-3 border border-n-strong rounded-xl bg-n-surface-2"
              >
                <span class="text-sm font-semibold text-n-slate-12">
                  {{ $t('BRANDING_SETTINGS.COLOR_SETTINGS.BACKGROUND') }}
                </span>
                <div class="flex items-center gap-2">
                  <input
                    v-model="backgroundColor"
                    type="color"
                    class="w-8 h-8 rounded cursor-pointer border border-n-strong bg-transparent"
                  />
                  <span
                    class="text-xs font-mono text-n-slate-11 select-all uppercase"
                  >
                    {{ backgroundColor }}
                  </span>
                </div>
              </div>
            </div>

            <!-- Live Preview -->
            <div class="flex flex-col gap-2">
              <span
                class="text-xs font-semibold text-n-slate-10 uppercase tracking-wider mb-1"
              >
                {{ $t('BRANDING_SETTINGS.COLOR_SETTINGS.LIVE_PREVIEW') }}
              </span>
              <div
                class="p-6 rounded-xl flex flex-col gap-4 items-center justify-center border border-n-strong transition-all duration-300 min-h-[140px]"
                :style="{ backgroundColor: backgroundColor }"
              >
                <p
                  class="text-sm font-medium transition-all duration-300"
                  :style="{ color: textColor }"
                >
                  {{ $t('BRANDING_SETTINGS.COLOR_SETTINGS.PREVIEW_TEXT') }}
                </p>
                <button
                  class="px-4 py-2 rounded-lg text-xs font-semibold shadow-sm transition-all duration-300"
                  :style="{
                    backgroundColor: primaryColor,
                    color: buttonTextColor,
                  }"
                >
                  {{ $t('BRANDING_SETTINGS.COLOR_SETTINGS.PREVIEW_BUTTON') }}
                </button>
              </div>
              <span class="text-xs text-n-slate-11 text-center">
                {{ $t('BRANDING_SETTINGS.COLOR_SETTINGS.PREVIEW_NOTE') }}
              </span>
            </div>
          </div>
        </SectionLayout>

        <!-- Action Buttons -->
        <div class="flex items-center justify-end gap-3 mt-6 pb-8">
          <NextButton type="button" clear @click="handleCancel">
            {{ $t('BRANDING_SETTINGS.CANCEL') }}
          </NextButton>
          <NextButton
            type="button"
            blue
            :is-loading="isUpdating"
            @click="handleSave"
          >
            {{ $t('BRANDING_SETTINGS.SAVE') }}
          </NextButton>
        </div>
      </div>
    </div>

    <MagicBrandingModal
      :show="isMagicModalOpen"
      @close="isMagicModalOpen = false"
      @apply="handleMagicPaletteApplied"
    />
  </div>
</template>
