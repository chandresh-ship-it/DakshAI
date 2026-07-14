<script setup>
import { ref, computed, watch } from 'vue';
import { useStore } from 'vuex';
import { useI18n } from 'vue-i18n';
import { useAccount } from 'dashboard/composables/useAccount';
import { useMapGetter } from 'dashboard/composables/store';
import { useAlert } from 'dashboard/composables';
import AccountAPI from 'dashboard/api/account';
import { LocalStorage } from 'shared/helpers/localStorage';
import { LOCAL_STORAGE_KEYS } from 'dashboard/constants/localStorage';
import { setColorTheme } from 'dashboard/helper/themeHelper';
import BaseSettingsHeader from '../components/BaseSettingsHeader.vue';
import SectionLayout from '../account/components/SectionLayout.vue';
import WithLabel from 'v3/components/Form/WithLabel.vue';
import NextInput from 'next/input/Input.vue';
import NextButton from 'dashboard/components-next/button/Button.vue';
import RadioCard from 'dashboard/components-next/radioCard/RadioCard.vue';
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

const PORTAL_LAYOUTS = {
  CLASSIC: 'classic',
  DOCUMENTATION: 'documentation',
};

const lightLogoInput = ref(null);
const faviconInput = ref(null);

const lightLogoFile = ref(null);
const faviconFile = ref(null);
const isMagicModalOpen = ref(false);

const lightLogoPreview = computed(() => {
  if (lightLogoFile.value)
    return window.URL.createObjectURL(lightLogoFile.value);
  const account = getAccount.value(accountId.value);
  return account?.logo_url || null;
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

const initFromAccount = () => {
  if (!activeAccount.value) return;
  customDomain.value = activeAccount.value.custom_domain || '';

  const colors = activeAccount.value.custom_attributes?.brand_colors || {};
  primaryColor.value = colors.primary || '#1F93FF';
  textColor.value = colors.text || '#FFFFFF';
  backgroundColor.value = colors.background || '#1A1E29';
  activeLayout.value = colors.layout || 'classic';
  brandName.value = colors.brand_name || '';
};

watch(activeAccount, initFromAccount, { immediate: true });

const handleCancel = () => {
  initFromAccount();
  lightLogoFile.value = null;
  faviconFile.value = null;
};

const handleSave = async () => {
  try {
    const formData = new FormData();
    if (customDomain.value)
      formData.append('custom_domain', customDomain.value);
    if (lightLogoFile.value) formData.append('logo', lightLogoFile.value);
    if (faviconFile.value) formData.append('favicon', faviconFile.value);

    // Send brand colors as nested hash
    formData.append('brand_colors[primary]', primaryColor.value);
    formData.append('brand_colors[text]', textColor.value);
    formData.append('brand_colors[background]', backgroundColor.value);
    formData.append('brand_colors[layout]', activeLayout.value);
    formData.append('brand_colors[brand_name]', brandName.value);

    store.commit('accounts/SET_ACCOUNT_UI_FLAG', { isUpdating: true });
    const response = await AccountAPI.update(formData);
    store.commit('accounts/EDIT_ACCOUNT', response.data);
    lightLogoFile.value = null;
    faviconFile.value = null;
    store.commit('accounts/SET_ACCOUNT_UI_FLAG', { isUpdating: false });

    // Automatically switch appearance to custom when branding colors are updated
    if (primaryColor.value || backgroundColor.value || textColor.value) {
      LocalStorage.set(LOCAL_STORAGE_KEYS.COLOR_SCHEME, 'custom');
      const isOSOnDarkMode = window.matchMedia(
        '(prefers-color-scheme: dark)'
      ).matches;
      setColorTheme(isOSOnDarkMode);
    }

    useAlert(t('BRANDING_SETTINGS.SAVE_SUCCESS'));
  } catch {
    store.commit('accounts/SET_ACCOUNT_UI_FLAG', { isUpdating: false });
    useAlert(t('BRANDING_SETTINGS.SAVE_ERROR'));
  }
};

const handleVerify = () => {
  handleSave();
};

const onLightLogoChange = event => {
  const [file] = event.target.files;
  if (file) lightLogoFile.value = file;
};

const onFaviconChange = event => {
  const [file] = event.target.files;
  if (file) faviconFile.value = file;
};

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
            </div>

            <div class="mt-2">
              <span
                v-if="isVerified"
                class="inline-flex items-center gap-1.5 px-2.5 py-1 text-xs font-semibold rounded-full bg-n-alpha-green text-emerald-500"
              >
                <span
                  class="w-1.5 h-1.5 rounded-full bg-emerald-500 animate-pulse"
                />
                {{ $t('BRANDING_SETTINGS.CUSTOM_DOMAIN.VERIFIED') }}
              </span>
              <span
                v-else-if="customDomain && isPending"
                class="inline-flex items-center gap-1.5 px-2.5 py-1 text-xs font-semibold rounded-full bg-n-alpha-amber text-amber-500"
              >
                <span class="w-1.5 h-1.5 rounded-full bg-amber-500" />
                {{ $t('BRANDING_SETTINGS.CUSTOM_DOMAIN.PENDING') }}
              </span>
            </div>
          </WithLabel>

          <div
            v-if="customDomain && isPending"
            class="mt-3 flex flex-col gap-3 p-4 bg-n-surface-2 border border-n-strong rounded-xl"
          >
            <div class="flex gap-2.5 items-start text-xs text-n-slate-11">
              <span
                class="i-lucide-info mt-0.5 size-4 text-n-slate-10 shrink-0"
              />
              <p class="leading-relaxed">
                {{ $t('BRANDING_SETTINGS.CUSTOM_DOMAIN.CNAME_INSTRUCTION') }}
              </p>
            </div>
            <div
              class="grid grid-cols-[auto,1fr] gap-x-4 gap-y-3 text-xs bg-n-surface-1 p-3 rounded-lg border border-n-strong"
            >
              <span class="text-n-slate-10 font-medium">{{ 'Type' }}</span>
              <code class="font-mono text-n-slate-12 font-medium">{{
                'CNAME'
              }}</code>

              <span class="text-n-slate-10 font-medium pt-0.5">{{
                'Name'
              }}</span>
              <code
                class="px-2 py-1 bg-n-surface-2 text-n-slate-11 rounded text-xs select-all break-all min-w-0 font-mono"
              >
                {{ customDomain }}
              </code>

              <span class="text-n-slate-10 font-medium pt-0.5">{{
                'Target'
              }}</span>
              <code
                class="px-2 py-1 bg-n-surface-2 text-n-slate-11 rounded text-xs select-all break-all min-w-0 font-mono"
              >
                {{ cnameTarget }}
              </code>
            </div>
          </div>
          <p v-else class="text-xs text-n-slate-11 mt-2">
            {{ $t('BRANDING_SETTINGS.CUSTOM_DOMAIN.CNAME_INSTRUCTION') }}
          </p>
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
          <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
            <!-- Primary Logo -->
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

        <!-- Layout Settings -->
        <SectionLayout
          with-border
          :title="$t('BRANDING_SETTINGS.LAYOUT_SETTINGS.TITLE')"
          :description="$t('BRANDING_SETTINGS.LAYOUT_SETTINGS.DESCRIPTION')"
        >
          <div class="grid grid-cols-1 sm:grid-cols-2 gap-3 text-n-slate-11">
            <RadioCard
              :id="PORTAL_LAYOUTS.CLASSIC"
              :is-active="activeLayout === PORTAL_LAYOUTS.CLASSIC"
              :label="$t('BRANDING_SETTINGS.LAYOUT_SETTINGS.CLASSIC.TITLE')"
              :description="
                $t('BRANDING_SETTINGS.LAYOUT_SETTINGS.CLASSIC.DESCRIPTION')
              "
              @select="value => (activeLayout = value)"
            >
              <div
                class="w-full mt-2 rounded-md overflow-hidden border border-solid border-n-weak bg-n-slate-2 dark:bg-n-slate-1"
              >
                <svg
                  viewBox="0 0 120 70"
                  class="w-full h-auto"
                  fill="none"
                  xmlns="http://www.w3.org/2000/svg"
                >
                  <rect
                    width="120"
                    height="70"
                    rx="4"
                    fill="currentColor"
                    class="text-n-surface-1"
                  />
                  <path
                    d="M4,0 L22,0 L22,70 L4,70 C1.79,70 0,68.21 0,66 L0,4 C0,1.79 1.79,0 4,0 Z"
                    fill="currentColor"
                    class="text-n-slate-2 dark:text-n-slate-1"
                  />
                  <line
                    x1="22"
                    y1="0"
                    x2="22"
                    y2="70"
                    stroke="currentColor"
                    class="text-n-weak"
                    stroke-width="0.5"
                  />
                  <rect
                    x="4"
                    y="6"
                    width="14"
                    height="4"
                    rx="1"
                    fill="currentColor"
                    class="text-n-slate-6 dark:text-n-slate-4"
                  />
                  <rect
                    x="4"
                    y="14"
                    width="14"
                    height="2"
                    rx="0.5"
                    fill="currentColor"
                    class="text-n-slate-5 dark:text-n-slate-3"
                  />
                  <rect
                    x="4"
                    y="19"
                    width="14"
                    height="2"
                    rx="0.5"
                    fill="currentColor"
                    class="text-n-slate-5 dark:text-n-slate-3"
                  />
                  <rect
                    x="4"
                    y="24"
                    width="14"
                    height="2"
                    rx="0.5"
                    fill="currentColor"
                    class="text-n-slate-5 dark:text-n-slate-3"
                  />
                  <rect
                    x="22"
                    y="0"
                    width="30"
                    height="70"
                    fill="currentColor"
                    class="text-n-slate-1 dark:text-n-slate-2"
                  />
                  <line
                    x1="52"
                    y1="0"
                    x2="52"
                    y2="70"
                    stroke="currentColor"
                    class="text-n-weak"
                    stroke-width="0.5"
                  />
                  <rect
                    x="26"
                    y="8"
                    width="22"
                    height="3"
                    rx="0.5"
                    fill="currentColor"
                    class="text-n-slate-4 dark:text-n-slate-3"
                  />
                  <rect
                    x="26"
                    y="13"
                    width="15"
                    height="2"
                    rx="0.5"
                    fill="currentColor"
                    class="text-n-slate-3 dark:text-n-slate-4"
                  />
                  <line
                    x1="22"
                    y1="20"
                    x2="52"
                    y2="20"
                    stroke="currentColor"
                    class="text-n-weak"
                    stroke-width="0.5"
                  />
                  <rect
                    x="26"
                    y="25"
                    width="22"
                    height="3"
                    rx="0.5"
                    fill="currentColor"
                    class="text-n-slate-4 dark:text-n-slate-3"
                  />
                  <rect
                    x="26"
                    y="30"
                    width="15"
                    height="2"
                    rx="0.5"
                    fill="currentColor"
                    class="text-n-slate-3 dark:text-n-slate-4"
                  />
                  <line
                    x1="22"
                    y1="37"
                    x2="52"
                    y2="37"
                    stroke="currentColor"
                    class="text-n-weak"
                    stroke-width="0.5"
                  />
                  <rect
                    x="58"
                    y="6"
                    width="35"
                    height="4"
                    rx="1"
                    fill="currentColor"
                    class="text-n-slate-6 dark:text-n-slate-4"
                  />
                  <line
                    x1="52"
                    y1="16"
                    x2="120"
                    y2="16"
                    stroke="currentColor"
                    class="text-n-weak"
                    stroke-width="0.5"
                  />
                  <rect
                    x="58"
                    y="24"
                    width="28"
                    height="6"
                    rx="2"
                    fill="currentColor"
                    class="text-n-slate-3 dark:text-n-slate-2"
                  />
                  <rect
                    x="86"
                    y="35"
                    width="28"
                    height="6"
                    rx="2"
                    fill="currentColor"
                    class="text-n-iris-9 dark:text-n-iris-8"
                  />
                </svg>
              </div>
            </RadioCard>

            <RadioCard
              :id="PORTAL_LAYOUTS.DOCUMENTATION"
              :is-active="activeLayout === PORTAL_LAYOUTS.DOCUMENTATION"
              :label="$t('BRANDING_SETTINGS.LAYOUT_SETTINGS.SIDEBAR.TITLE')"
              :description="
                $t('BRANDING_SETTINGS.LAYOUT_SETTINGS.SIDEBAR.DESCRIPTION')
              "
              @select="value => (activeLayout = value)"
            >
              <div
                class="w-full mt-2 rounded-md overflow-hidden border border-solid border-n-weak bg-n-slate-2 dark:bg-n-slate-1"
              >
                <svg
                  viewBox="0 0 120 70"
                  class="w-full h-auto"
                  fill="none"
                  xmlns="http://www.w3.org/2000/svg"
                >
                  <rect
                    width="120"
                    height="70"
                    rx="4"
                    fill="currentColor"
                    class="text-n-slate-2 dark:text-n-slate-3"
                  />
                  <rect
                    x="4"
                    y="4"
                    width="88"
                    height="62"
                    rx="3"
                    fill="currentColor"
                    class="text-n-surface-1"
                  />
                  <rect
                    x="10"
                    y="10"
                    width="30"
                    height="4"
                    rx="1"
                    fill="currentColor"
                    class="text-n-slate-5 dark:text-n-slate-4"
                  />
                  <line
                    x1="4"
                    y1="18"
                    x2="92"
                    y2="18"
                    stroke="currentColor"
                    class="text-n-weak"
                    stroke-width="0.5"
                  />
                  <rect
                    x="4"
                    y="18"
                    width="26"
                    height="48"
                    fill="currentColor"
                    class="text-n-slate-1 dark:text-n-slate-2"
                  />
                  <line
                    x1="30"
                    y1="18"
                    x2="30"
                    y2="66"
                    stroke="currentColor"
                    class="text-n-weak"
                    stroke-width="0.5"
                  />
                  <rect
                    x="8"
                    y="24"
                    width="18"
                    height="2"
                    rx="0.5"
                    fill="currentColor"
                    class="text-n-slate-4 dark:text-n-slate-3"
                  />
                  <rect
                    x="8"
                    y="28"
                    width="12"
                    height="1.5"
                    rx="0.5"
                    fill="currentColor"
                    class="text-n-slate-3 dark:text-n-slate-4"
                  />
                  <line
                    x1="4"
                    y1="33"
                    x2="30"
                    y2="33"
                    stroke="currentColor"
                    class="text-n-weak"
                    stroke-width="0.5"
                  />
                  <rect
                    x="36"
                    y="24"
                    width="24"
                    height="5"
                    rx="1.5"
                    fill="currentColor"
                    class="text-n-slate-3 dark:text-n-slate-2"
                  />
                  <rect
                    x="64"
                    y="33"
                    width="24"
                    height="5"
                    rx="1.5"
                    fill="currentColor"
                    class="text-n-iris-9 dark:text-n-iris-8"
                  />
                  <rect
                    x="96"
                    y="4"
                    width="20"
                    height="62"
                    rx="3"
                    fill="currentColor"
                    class="text-n-slate-6 dark:text-n-slate-4"
                  />
                  <rect
                    x="99"
                    y="8"
                    width="14"
                    height="4"
                    rx="1"
                    fill="currentColor"
                    class="text-n-slate-9 dark:text-n-slate-6"
                  />
                  <rect
                    x="99"
                    y="16"
                    width="14"
                    height="2"
                    rx="0.5"
                    fill="currentColor"
                    class="text-n-slate-8 dark:text-n-slate-5"
                  />
                  <rect
                    x="99"
                    y="21"
                    width="14"
                    height="2"
                    rx="0.5"
                    fill="currentColor"
                    class="text-n-slate-8 dark:text-n-slate-5"
                  />
                  <rect
                    x="99"
                    y="26"
                    width="14"
                    height="2"
                    rx="0.5"
                    fill="currentColor"
                    class="text-n-slate-8 dark:text-n-slate-5"
                  />
                </svg>
              </div>
            </RadioCard>
          </div>
        </SectionLayout>

        <!-- Color Customization -->
        <SectionLayout
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

          <div class="flex flex-col gap-4">
            <div
              class="flex items-center justify-between p-3 border border-n-strong rounded-lg bg-n-surface-2"
            >
              <span class="text-sm font-medium text-n-slate-12">
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
              class="flex items-center justify-between p-3 border border-n-strong rounded-lg bg-n-surface-2"
            >
              <span class="text-sm font-medium text-n-slate-12">
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
              class="flex items-center justify-between p-3 border border-n-strong rounded-lg bg-n-surface-2"
            >
              <span class="text-sm font-medium text-n-slate-12">
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
