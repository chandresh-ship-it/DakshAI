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
import SettingsLayout from '../SettingsLayout.vue';
import SectionLayout from '../account/components/SectionLayout.vue';
import WithLabel from 'v3/components/Form/WithLabel.vue';
import NextInput from 'next/input/Input.vue';
import NextButton from 'dashboard/components-next/button/Button.vue';

const store = useStore();
const { t } = useI18n();
const { accountId } = useAccount();

const getAccount = useMapGetter('accounts/getAccount');
const uiFlags = useMapGetter('accounts/getUIFlags');
const isUpdating = computed(() => uiFlags.value.isUpdating);

const customDomain = ref('');
const isVerified = ref(false);
const primaryColor = ref('#1F93FF');
const textColor = ref('#FFFFFF');
const backgroundColor = ref('#1A1E29');

const lightLogoInput = ref(null);
const darkLogoInput = ref(null);
const faviconInput = ref(null);

const lightLogoFile = ref(null);
const darkLogoFile = ref(null);
const faviconFile = ref(null);

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

const initFromAccount = () => {
  if (!activeAccount.value) return;
  customDomain.value = activeAccount.value.custom_domain || '';

  const colors = activeAccount.value.custom_attributes?.brand_colors || {};
  primaryColor.value = colors.primary || '#1F93FF';
  textColor.value = colors.text || '#FFFFFF';
  backgroundColor.value = colors.background || '#1A1E29';
};

watch(activeAccount, initFromAccount, { immediate: true });

const handleVerify = () => {
  isVerified.value = !isVerified.value;
};

const handleCancel = () => {
  initFromAccount();
  lightLogoFile.value = null;
  darkLogoFile.value = null;
  faviconFile.value = null;
};

const handleSave = async () => {
  try {
    const formData = new FormData();
    if (customDomain.value)
      formData.append('custom_domain', customDomain.value);
    if (lightLogoFile.value) formData.append('logo', lightLogoFile.value);
    if (darkLogoFile.value) formData.append('dark_logo', darkLogoFile.value);
    if (faviconFile.value) formData.append('favicon', faviconFile.value);

    // Send brand colors as nested hash
    formData.append('brand_colors[primary]', primaryColor.value);
    formData.append('brand_colors[text]', textColor.value);
    formData.append('brand_colors[background]', backgroundColor.value);

    store.commit('accounts/SET_ACCOUNT_UI_FLAG', { isUpdating: true });
    const response = await AccountAPI.update(formData);
    store.commit('accounts/EDIT_ACCOUNT', response.data);
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
</script>

<template>
  <SettingsLayout :no-records-found="false">
    <template #header>
      <BaseSettingsHeader
        :title="$t('BRANDING_SETTINGS.TITLE')"
        :description="$t('BRANDING_SETTINGS.DESCRIPTION')"
        feature-name="branding"
      />
    </template>

    <template #body>
      <div class="flex flex-col w-full max-w-2xl">
        <!-- Custom Domain -->
        <SectionLayout
          :title="$t('BRANDING_SETTINGS.CUSTOM_DOMAIN.TITLE')"
          :description="$t('BRANDING_SETTINGS.CUSTOM_DOMAIN.DESCRIPTION')"
          class="!pt-0 border-b border-n-weak"
        >
          <WithLabel
            name="custom-domain"
            :label="$t('BRANDING_SETTINGS.CUSTOM_DOMAIN.LABEL')"
          >
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
                v-else-if="customDomain"
                class="inline-flex items-center gap-1.5 px-2.5 py-1 text-xs font-semibold rounded-full bg-n-alpha-amber text-amber-500"
              >
                <span class="w-1.5 h-1.5 rounded-full bg-amber-500" />
                {{ $t('BRANDING_SETTINGS.CUSTOM_DOMAIN.PENDING') }}
              </span>
            </div>

            <p class="text-xs text-n-slate-11 mt-2">
              {{ $t('BRANDING_SETTINGS.CUSTOM_DOMAIN.CNAME_INSTRUCTION') }}
            </p>
          </WithLabel>
        </SectionLayout>

        <!-- Logo Upload -->
        <SectionLayout
          :title="$t('BRANDING_SETTINGS.LOGO_SETTINGS.TITLE')"
          :description="$t('BRANDING_SETTINGS.LOGO_SETTINGS.DESCRIPTION')"
          class="border-b border-n-weak"
        >
          <div class="grid grid-cols-1 md:grid-cols-3 gap-6">
            <!-- Light Mode Logo -->
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
                  v-if="lightLogoFile"
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

            <!-- Dark Mode Logo -->
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
                class="w-16 h-16 rounded-lg bg-slate-900 border border-n-strong flex items-center justify-center mb-4 overflow-hidden"
              >
                <img
                  v-if="darkLogoFile"
                  :src="darkLogoPreview"
                  class="w-full h-full object-contain"
                  :alt="$t('BRANDING_SETTINGS.LOGO_SETTINGS.DARK_LOGO.TITLE')"
                />
                <span v-else class="i-lucide-image text-slate-600 size-6" />
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
                  v-if="faviconFile"
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

        <!-- Color Customization -->
        <SectionLayout
          :title="$t('BRANDING_SETTINGS.COLOR_SETTINGS.TITLE')"
          :description="$t('BRANDING_SETTINGS.COLOR_SETTINGS.DESCRIPTION')"
        >
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
    </template>
  </SettingsLayout>
</template>
