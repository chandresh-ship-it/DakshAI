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
import ColorPicker from 'dashboard/components-next/colorpicker/ColorPicker.vue';
import { getContrast } from 'color2k';
import {
  generatePrimaryColorVariables,
  generateThemeVariables,
  hexToRgbSpace,
  clearCustomThemeVariables,
} from 'dashboard/helper/colorHelper';
import BaseSettingsHeader from '../components/BaseSettingsHeader.vue';
import SectionLayout from '../account/components/SectionLayout.vue';
import { RelayButton, RelayInput } from 'dashboard/components-next/relay';
import MagicBrandingModal from './components/MagicBrandingModal.vue';

const DEFAULT_PRIMARY = '#1F93FF';
const DEFAULT_TEXT = '#FFFFFF';
const DEFAULT_BACKGROUND = '#1A1E29';

const store = useStore();
const { t } = useI18n();
const { accountId } = useAccount();

const getAccount = useMapGetter('accounts/getAccount');
const uiFlags = useMapGetter('accounts/getUIFlags');
const isUpdating = computed(() => uiFlags.value.isUpdating);

const companyName = ref('');
const brandName = ref('');
const primaryColor = ref(DEFAULT_PRIMARY);
const textColor = ref(DEFAULT_TEXT);
const backgroundColor = ref(DEFAULT_BACKGROUND);
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

  const isOSOnDarkMode = window.matchMedia(
    '(prefers-color-scheme: dark)'
  ).matches;

  if (theme !== 'custom') {
    clearCustomThemeVariables();
    setColorTheme(theme === 'dark', null);
  } else {
    applyLivePreview();
    setColorTheme(isOSOnDarkMode, {
      primary: primaryColor.value,
      text: textColor.value,
      background: backgroundColor.value,
    });
  }
  window.dispatchEvent(new CustomEvent('theme-changed'));
};

let skipNextAccountSync = false;
const initFromAccount = () => {
  if (skipNextAccountSync) {
    skipNextAccountSync = false;
    return;
  }
  if (!activeAccount.value) return;
  isWatcherEnabled = false;

  companyName.value = activeAccount.value.name || '';
  const colors = activeAccount.value.custom_attributes?.brand_colors || {};
  primaryColor.value = colors.primary || DEFAULT_PRIMARY;
  textColor.value = colors.text || DEFAULT_TEXT;
  backgroundColor.value = colors.background || DEFAULT_BACKGROUND;
  activeLayout.value = colors.layout || 'classic';
  brandName.value = activeAccount.value.brand_name || colors.brand_name || '';

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

const handleResetColors = () => {
  primaryColor.value = DEFAULT_PRIMARY;
  textColor.value = DEFAULT_TEXT;
  backgroundColor.value = DEFAULT_BACKGROUND;
  setTheme('light');
};

const handleSave = async (shouldReload = true) => {
  try {
    const formData = new FormData();
    formData.append('name', companyName.value || '');
    if (lightLogoFile.value) formData.append('logo', lightLogoFile.value);
    if (darkLogoFile.value) formData.append('dark_logo', darkLogoFile.value);
    if (faviconFile.value) formData.append('favicon', faviconFile.value);

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
    formData.append('brand_name', brandName.value);

    store.commit('accounts/SET_ACCOUNT_UI_FLAG', { isUpdating: true });
    const response = await AccountAPI.update(formData);

    LocalStorage.set(LOCAL_STORAGE_KEYS.COLOR_SCHEME, activeTheme.value);
    skipNextAccountSync = true;
    store.commit('accounts/EDIT_ACCOUNT', response.data);
    lightLogoFile.value = null;
    darkLogoFile.value = null;
    faviconFile.value = null;
    store.commit('accounts/SET_ACCOUNT_UI_FLAG', { isUpdating: false });

    const isOSOnDarkMode = window.matchMedia(
      '(prefers-color-scheme: dark)'
    ).matches;

    if (activeTheme.value === 'custom') {
      applyLivePreview();
      setColorTheme(isOSOnDarkMode, {
        primary: primaryColor.value,
        text: textColor.value,
        background: backgroundColor.value,
      });
    } else {
      clearCustomThemeVariables();
      setColorTheme(activeTheme.value === 'dark', null);
    }

    useAlert(t('BRANDING_SETTINGS.SAVE_SUCCESS'));

    if (shouldReload) {
      setTimeout(() => {
        window.location.reload();
      }, 500);
    }
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

    const isOSOnDarkMode = window.matchMedia(
      '(prefers-color-scheme: dark)'
    ).matches;
    setColorTheme(isOSOnDarkMode, {
      primary: primaryColor.value,
      text: textColor.value,
      background: backgroundColor.value,
    });
  },
  { deep: true }
);

const handleMagicPaletteApplied = palette => {
  if (palette.primary) primaryColor.value = palette.primary;
  if (palette.text) textColor.value = palette.text;
  if (palette.background) backgroundColor.value = palette.background;
};

const themeOptions = computed(() => [
  {
    id: 'light',
    icon: 'i-lucide-sun',
    label: t('BRANDING_SETTINGS.THEME_SETTINGS.LIGHT.TITLE'),
  },
  {
    id: 'dark',
    icon: 'i-lucide-moon',
    label: t('BRANDING_SETTINGS.THEME_SETTINGS.DARK.TITLE'),
  },
  {
    id: 'custom',
    icon: 'i-lucide-palette',
    label: t('BRANDING_SETTINGS.THEME_SETTINGS.CUSTOM.TITLE'),
  },
]);
</script>

<template>
  <div class="flex w-full max-w-3xl flex-col gap-8 ltr:mr-auto rtl:ml-auto">
    <BaseSettingsHeader
      :title="$t('BRANDING_SETTINGS.TITLE')"
      :description="$t('BRANDING_SETTINGS.DESCRIPTION')"
      feature-name="branding"
    />

    <!-- Brand Identity -->
    <SectionLayout
      as-card
      icon="i-lucide-paintbrush"
      :title="$t('BRANDING_SETTINGS.BRAND_IDENTITY.TITLE')"
      :description="$t('BRANDING_SETTINGS.BRAND_IDENTITY.DESCRIPTION')"
    >
      <div class="space-y-8">
        <div class="grid grid-cols-1 gap-6 md:grid-cols-2">
          <div class="space-y-2">
            <label class="block text-sm font-medium text-foreground">
              {{ $t('BRANDING_SETTINGS.COMPANY_NAME.LABEL') }}
            </label>
            <RelayInput
              v-model="companyName"
              class-name="h-10 bg-background transition-colors hover:bg-accent/30 focus:bg-background"
              :placeholder="$t('BRANDING_SETTINGS.COMPANY_NAME.PLACEHOLDER')"
            />
          </div>
          <div class="space-y-2">
            <label class="block text-sm font-medium text-foreground">
              {{ $t('BRANDING_SETTINGS.BRAND_NAME.LABEL') }}
            </label>
            <RelayInput
              v-model="brandName"
              class-name="h-10 bg-background transition-colors hover:bg-accent/30 focus:bg-background"
              :placeholder="$t('BRANDING_SETTINGS.BRAND_NAME.PLACEHOLDER')"
            />
          </div>
        </div>

        <div>
          <label class="mb-4 block text-sm font-medium text-foreground">
            {{ $t('BRANDING_SETTINGS.LOGO_SETTINGS.TITLE') }}
          </label>
          <div class="grid grid-cols-1 gap-6 md:grid-cols-3">
            <!-- Light Logo -->
            <div
              class="group flex cursor-pointer flex-col items-center rounded-xl border border-border/60 bg-card p-5 text-center shadow-sm transition-all duration-300 hover:border-primary/30 hover:bg-accent/50 hover:shadow-md"
              @click="lightLogoInput?.click()"
            >
              <div
                class="my-3 flex size-16 items-center justify-center overflow-hidden rounded-2xl border border-dashed border-border/80 bg-muted/40 transition-all duration-300 group-hover:scale-105 group-hover:border-primary/40 group-hover:bg-primary/5"
              >
                <img
                  v-if="lightLogoPreview"
                  :src="lightLogoPreview"
                  class="size-full object-contain"
                  :alt="$t('BRANDING_SETTINGS.LOGO_SETTINGS.LIGHT_LOGO.TITLE')"
                />
                <span
                  v-else
                  class="i-lucide-sun size-6 text-muted-foreground/60 transition-colors group-hover:text-primary/80"
                />
              </div>
              <h4 class="text-sm font-medium text-foreground">
                {{ $t('BRANDING_SETTINGS.LOGO_SETTINGS.LIGHT_LOGO.TITLE') }}
              </h4>
              <p class="mt-1 text-[11px] leading-relaxed text-muted-foreground">
                {{ $t('BRANDING_SETTINGS.LOGO_SETTINGS.LIGHT_LOGO.NOTE') }}
              </p>
              <input
                ref="lightLogoInput"
                type="file"
                accept="image/*"
                class="hidden"
                @change="onLightLogoChange"
                @click.stop
              />
              <RelayButton
                variant="outline"
                size="sm"
                class="mt-5 h-8 w-full bg-background text-xs font-medium shadow-none transition-colors group-hover:border-transparent group-hover:bg-primary group-hover:text-primary-foreground"
                type="button"
                @click.stop="lightLogoInput?.click()"
              >
                {{
                  lightLogoFile
                    ? lightLogoFile.name
                    : $t('BRANDING_SETTINGS.LOGO_SETTINGS.CHOOSE_FILE')
                }}
              </RelayButton>
            </div>

            <!-- Dark Logo -->
            <div
              class="group flex cursor-pointer flex-col items-center rounded-xl border border-border/60 bg-card p-5 text-center shadow-sm transition-all duration-300 hover:border-primary/30 hover:bg-accent/50 hover:shadow-md"
              @click="darkLogoInput?.click()"
            >
              <div
                class="my-3 flex size-16 items-center justify-center overflow-hidden rounded-2xl border border-dashed border-border/80 bg-muted/40 transition-all duration-300 group-hover:scale-105 group-hover:border-primary/40 group-hover:bg-primary/5"
              >
                <img
                  v-if="darkLogoPreview"
                  :src="darkLogoPreview"
                  class="size-full object-contain"
                  :alt="$t('BRANDING_SETTINGS.LOGO_SETTINGS.DARK_LOGO.TITLE')"
                />
                <span
                  v-else
                  class="i-lucide-moon size-6 text-muted-foreground/60 transition-colors group-hover:text-primary/80"
                />
              </div>
              <h4 class="text-sm font-medium text-foreground">
                {{ $t('BRANDING_SETTINGS.LOGO_SETTINGS.DARK_LOGO.TITLE') }}
              </h4>
              <p class="mt-1 text-[11px] leading-relaxed text-muted-foreground">
                {{ $t('BRANDING_SETTINGS.LOGO_SETTINGS.DARK_LOGO.NOTE') }}
              </p>
              <input
                ref="darkLogoInput"
                type="file"
                accept="image/*"
                class="hidden"
                @change="onDarkLogoChange"
                @click.stop
              />
              <RelayButton
                variant="outline"
                size="sm"
                class="mt-5 h-8 w-full bg-background text-xs font-medium shadow-none transition-colors group-hover:border-transparent group-hover:bg-primary group-hover:text-primary-foreground"
                type="button"
                @click.stop="darkLogoInput?.click()"
              >
                {{
                  darkLogoFile
                    ? darkLogoFile.name
                    : $t('BRANDING_SETTINGS.LOGO_SETTINGS.CHOOSE_FILE')
                }}
              </RelayButton>
            </div>

            <!-- Favicon -->
            <div
              class="group flex cursor-pointer flex-col items-center rounded-xl border border-border/60 bg-card p-5 text-center shadow-sm transition-all duration-300 hover:border-primary/30 hover:bg-accent/50 hover:shadow-md"
              @click="faviconInput?.click()"
            >
              <div
                class="my-5 flex size-12 items-center justify-center overflow-hidden rounded-xl border border-dashed border-border/80 bg-muted/40 transition-all duration-300 group-hover:scale-105 group-hover:border-primary/40 group-hover:bg-primary/5"
              >
                <img
                  v-if="faviconPreview"
                  :src="faviconPreview"
                  class="size-full object-contain"
                  :alt="$t('BRANDING_SETTINGS.LOGO_SETTINGS.FAVICON.TITLE')"
                />
                <span
                  v-else
                  class="i-lucide-globe size-5 text-muted-foreground/60 transition-colors group-hover:text-primary/80"
                />
              </div>
              <h4 class="text-sm font-medium text-foreground">
                {{ $t('BRANDING_SETTINGS.LOGO_SETTINGS.FAVICON.TITLE') }}
              </h4>
              <p class="mt-1 text-[11px] leading-relaxed text-muted-foreground">
                {{ $t('BRANDING_SETTINGS.LOGO_SETTINGS.FAVICON.NOTE') }}
              </p>
              <input
                ref="faviconInput"
                type="file"
                accept="image/x-icon,image/png,image/svg+xml"
                class="hidden"
                @change="onFaviconChange"
                @click.stop
              />
              <RelayButton
                variant="outline"
                size="sm"
                class="mt-5 h-8 w-full bg-background text-xs font-medium shadow-none transition-colors group-hover:border-transparent group-hover:bg-primary group-hover:text-primary-foreground"
                type="button"
                @click.stop="faviconInput?.click()"
              >
                {{
                  faviconFile
                    ? faviconFile.name
                    : $t('BRANDING_SETTINGS.LOGO_SETTINGS.CHOOSE_FILE')
                }}
              </RelayButton>
            </div>
          </div>
        </div>

        <!-- Theme Preset -->
        <div
          class="flex flex-col justify-between gap-4 border-t border-border/40 pt-6 md:flex-row md:items-center"
        >
          <div>
            <label
              class="flex items-center gap-2 text-sm font-medium text-foreground"
            >
              <span class="i-lucide-palette size-4 text-muted-foreground" />
              {{ $t('BRANDING_SETTINGS.THEME_SETTINGS.TITLE') }}
            </label>
            <p class="mt-1 text-sm text-muted-foreground">
              {{ $t('BRANDING_SETTINGS.THEME_SETTINGS.DESCRIPTION') }}
            </p>
          </div>
          <div
            class="inline-flex shrink-0 items-center gap-1 rounded-lg border border-border bg-background p-1 shadow-xs"
          >
            <button
              v-for="option in themeOptions"
              :key="option.id"
              type="button"
              class="inline-flex items-center gap-1.5 rounded-md px-2.5 py-1.5 text-xs font-medium transition-colors"
              :class="
                activeTheme === option.id
                  ? 'bg-muted text-foreground'
                  : 'text-muted-foreground hover:bg-accent hover:text-foreground'
              "
              @click="setTheme(option.id)"
            >
              <span class="size-3.5" :class="[option.icon]" />
              {{ option.label }}
            </button>
          </div>
        </div>
      </div>
    </SectionLayout>

    <!-- Brand Colors -->
    <SectionLayout
      as-card
      :title="$t('BRANDING_SETTINGS.COLOR_SETTINGS.TITLE')"
      :description="$t('BRANDING_SETTINGS.COLOR_SETTINGS.DESCRIPTION')"
    >
      <template #headerActions>
        <div class="flex flex-wrap gap-2">
          <RelayButton
            variant="outline"
            class="h-9 gap-2 text-[13px] shadow-none"
            type="button"
            @click="isMagicModalOpen = true"
          >
            <span class="i-lucide-globe size-3.5" />
            {{ $t('BRANDING_SETTINGS.MAGIC_AI.GENERATE_FROM_WEBSITE') }}
          </RelayButton>
          <RelayButton
            variant="outline"
            class="h-9 text-[13px] shadow-none"
            type="button"
            @click="handleResetColors"
          >
            {{ $t('BRANDING_SETTINGS.COLOR_SETTINGS.RESET') }}
          </RelayButton>
        </div>
      </template>

      <div class="flex flex-col gap-6">
        <div class="flex flex-wrap items-center gap-8">
          <div>
            <span class="mb-3 block text-xs font-medium text-muted-foreground">
              {{ $t('BRANDING_SETTINGS.COLOR_SETTINGS.PRIMARY') }}
            </span>
            <ColorPicker v-model="primaryColor" />
          </div>
          <div>
            <span class="mb-3 block text-xs font-medium text-muted-foreground">
              {{ $t('BRANDING_SETTINGS.COLOR_SETTINGS.TEXT') }}
            </span>
            <ColorPicker v-model="textColor" />
          </div>
          <div>
            <span class="mb-3 block text-xs font-medium text-muted-foreground">
              {{ $t('BRANDING_SETTINGS.COLOR_SETTINGS.BACKGROUND') }}
            </span>
            <ColorPicker v-model="backgroundColor" />
          </div>
        </div>

        <div v-if="activeTheme === 'custom'" class="flex flex-col gap-2">
          <span
            class="mb-1 text-xs font-semibold uppercase tracking-wider text-muted-foreground"
          >
            {{ $t('BRANDING_SETTINGS.COLOR_SETTINGS.LIVE_PREVIEW') }}
          </span>
          <div
            class="flex min-h-[140px] flex-col items-center justify-center gap-4 rounded-xl border border-border p-6 transition-all duration-300"
            :style="{ backgroundColor: backgroundColor }"
          >
            <p
              class="text-sm font-medium transition-all duration-300"
              :style="{ color: textColor }"
            >
              {{ $t('BRANDING_SETTINGS.COLOR_SETTINGS.PREVIEW_TEXT') }}
            </p>
            <button
              type="button"
              class="rounded-lg px-4 py-2 text-xs font-semibold shadow-sm transition-all duration-300"
              :style="{
                backgroundColor: primaryColor,
                color: buttonTextColor,
              }"
            >
              {{ $t('BRANDING_SETTINGS.COLOR_SETTINGS.PREVIEW_BUTTON') }}
            </button>
          </div>
          <span class="text-center text-xs text-muted-foreground">
            {{ $t('BRANDING_SETTINGS.COLOR_SETTINGS.PREVIEW_NOTE') }}
          </span>
        </div>
      </div>
    </SectionLayout>

    <div
      class="mt-2 flex items-center justify-end gap-3 border-t border-border/40 pb-2 pt-6"
    >
      <RelayButton variant="outline" type="button" @click="handleCancel">
        {{ $t('BRANDING_SETTINGS.CANCEL') }}
      </RelayButton>
      <RelayButton
        type="button"
        class="shadow-sm"
        :disabled="isUpdating"
        @click="handleSave"
      >
        {{ $t('BRANDING_SETTINGS.SAVE') }}
      </RelayButton>
    </div>

    <MagicBrandingModal
      :show="isMagicModalOpen"
      @close="isMagicModalOpen = false"
      @apply="handleMagicPaletteApplied"
    />
  </div>
</template>
