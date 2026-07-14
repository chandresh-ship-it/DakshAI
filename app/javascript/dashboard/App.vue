<script>
import { mapGetters } from 'vuex';
import LoadingState from './components/widgets/LoadingState.vue';
import NetworkNotification from './components/NetworkNotification.vue';
import UpdateBanner from './components/app/UpdateBanner.vue';
import StatusBanner from './components/app/StatusBanner.vue';
import PaymentPendingBanner from './components/app/PaymentPendingBanner.vue';
import PendingEmailVerificationBanner from './components/app/PendingEmailVerificationBanner.vue';
import vueActionCable from './helper/actionCable';
import { useRouter } from 'vue-router';
import { useStore } from 'dashboard/composables/store';
import WootSnackbarBox from './components/SnackbarContainer.vue';
import { setColorTheme } from './helper/themeHelper';
import {
  hexToRgbSpace,
  generateThemeVariables,
  generatePrimaryColorVariables,
  clearCustomThemeVariables,
} from './helper/colorHelper';
import { isOnOnboardingView } from 'v3/helpers/RouteHelper';
import { useAccount } from 'dashboard/composables/useAccount';
import { useFontSize } from 'dashboard/composables/useFontSize';
import {
  registerSubscription,
  verifyServiceWorkerExistence,
} from './helper/pushHelper';
import ReconnectService from 'dashboard/helper/ReconnectService';
import { useUISettings } from 'dashboard/composables/useUISettings';

export default {
  name: 'App',

  components: {
    LoadingState,
    NetworkNotification,
    UpdateBanner,
    StatusBanner,
    PaymentPendingBanner,
    WootSnackbarBox,
    PendingEmailVerificationBanner,
  },
  setup() {
    const router = useRouter();
    const store = useStore();
    const { accountId } = useAccount();
    // Use the font size composable (it automatically sets up the watcher)
    const { currentFontSize } = useFontSize();
    const { uiSettings } = useUISettings();

    return {
      router,
      store,
      currentAccountId: accountId,
      currentFontSize,
      uiSettings,
    };
  },
  data() {
    return {
      latestChatwootVersion: null,
      reconnectService: null,
    };
  },
  computed: {
    ...mapGetters({
      getAccount: 'accounts/getAccount',
      isRTL: 'accounts/isRTL',
      currentUser: 'getCurrentUser',
      authUIFlags: 'getAuthUIFlags',
    }),
    hideOnOnboardingView() {
      return !isOnOnboardingView(this.$route);
    },
    accountBrandColors() {
      if (!this.currentAccountId) return null;
      const account = this.getAccount(this.currentAccountId);
      return account?.custom_attributes?.brand_colors;
    },
  },

  watch: {
    currentAccountId: {
      immediate: true,
      handler() {
        if (this.currentAccountId) {
          this.initializeAccount();
        }
      },
    },
    accountBrandColors: {
      deep: true,
      handler(newColors) {
        if (newColors) {
          this.applyBrandColors(newColors);
          this.initializeColorTheme();
        }
      },
    },
  },
  mounted() {
    this.initializeColorTheme();
    this.listenToThemeChanges();
    // Eagerly apply global brand colors (e.g., for login page) before user logs in
    if (window.globalConfig && window.globalConfig.BRAND_COLORS) {
      this.applyBrandColors(window.globalConfig.BRAND_COLORS);
    }
    // If user locale is set, use it; otherwise use account locale
    this.setLocale(
      this.uiSettings?.locale || window.chatwootConfig.selectedLocale
    );
    window.addEventListener('theme-changed', this.handleThemeChange);
  },
  unmounted() {
    if (this.reconnectService) {
      this.reconnectService.disconnect();
    }
    window.removeEventListener('theme-changed', this.handleThemeChange);
  },
  methods: {
    handleThemeChange() {
      if (this.accountBrandColors) {
        this.applyBrandColors(this.accountBrandColors);
      }
    },
    initializeColorTheme() {
      setColorTheme(
        window.matchMedia('(prefers-color-scheme: dark)').matches,
        this.accountBrandColors
      );
    },
    listenToThemeChanges() {
      const mql = window.matchMedia('(prefers-color-scheme: dark)');
      mql.onchange = e => setColorTheme(e.matches, this.accountBrandColors);
    },
    applyBrandColors(colors) {
      const selectedColorScheme =
        window.localStorage.getItem('color_scheme') || 'auto';
      const hasDomainBranding =
        window.globalConfig && window.globalConfig.BRAND_COLORS;

      if (
        selectedColorScheme === 'light' ||
        selectedColorScheme === 'dark' ||
        (selectedColorScheme !== 'custom' &&
          !hasDomainBranding &&
          this.currentAccountId)
      ) {
        clearCustomThemeVariables();
        return;
      }

      if (!colors) return;
      const { primary, text, background } = colors;

      if (primary) {
        const primaryVars = generatePrimaryColorVariables(primary);
        if (primaryVars) {
          Object.entries(primaryVars).forEach(([key, value]) => {
            if (value) document.documentElement.style.setProperty(key, value);
          });
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

    setLocale(locale) {
      if (locale) {
        this.$root.$i18n.locale = locale;
      }
    },
    async initializeAccount() {
      await this.$store.dispatch('accounts/get');
      this.$store.dispatch('setActiveAccount', {
        accountId: this.currentAccountId,
      });
      const account = this.getAccount(this.currentAccountId);
      const { locale, latest_chatwoot_version: latestChatwootVersion } =
        account;
      const { pubsub_token: pubsubToken } = this.currentUser || {};
      // If user locale is set, use it; otherwise use account locale
      this.setLocale(this.uiSettings?.locale || locale);

      if (account?.custom_attributes?.brand_colors) {
        this.applyBrandColors(account.custom_attributes.brand_colors);
      }

      this.latestChatwootVersion = latestChatwootVersion;
      vueActionCable.init(this.store, pubsubToken);
      this.reconnectService = new ReconnectService(this.store, this.router);
      window.reconnectService = this.reconnectService;

      verifyServiceWorkerExistence(registration =>
        registration.pushManager.getSubscription().then(subscription => {
          if (subscription) {
            registerSubscription();
          }
        })
      );
    },
  },
};
</script>

<template>
  <div
    v-if="!authUIFlags.isFetching"
    id="app"
    class="flex flex-col w-full h-screen min-h-0 bg-n-background"
    :dir="isRTL ? 'rtl' : 'ltr'"
  >
    <UpdateBanner :latest-chatwoot-version="latestChatwootVersion" />
    <StatusBanner />
    <template v-if="currentAccountId">
      <PendingEmailVerificationBanner v-if="hideOnOnboardingView" />
      <PaymentPendingBanner v-if="hideOnOnboardingView" />
    </template>
    <router-view v-slot="{ Component }">
      <transition name="fade" mode="out-in">
        <component :is="Component" />
      </transition>
    </router-view>
    <WootSnackbarBox />
    <NetworkNotification />
  </div>
  <LoadingState v-else />
</template>

<style lang="scss">
@import './assets/scss/app';

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
