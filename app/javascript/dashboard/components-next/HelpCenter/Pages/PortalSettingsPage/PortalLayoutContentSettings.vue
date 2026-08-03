<script setup>
import { computed, reactive, ref, watch } from 'vue';
import { useI18n } from 'vue-i18n';

import classicLayoutPreview from './classic-layout-preview.svg?raw';
import documentationLayoutPreview from './documentation-layout-preview.svg?raw';
import { RelayButton } from 'dashboard/components-next/relay';
import Icon from 'dashboard/components-next/icon/Icon.vue';
import DropdownMenu from 'dashboard/components-next/dropdown-menu/DropdownMenu.vue';
import RadioCard from 'dashboard/components-next/radioCard/RadioCard.vue';

const props = defineProps({
  activePortal: { type: Object, required: true },
  isFetching: { type: Boolean, default: false },
});

const emit = defineEmits(['updatePortalConfiguration']);

const { t } = useI18n();

const PORTAL_LAYOUTS = {
  CLASSIC: 'classic',
  DOCUMENTATION: 'documentation',
};

// `prefix` is the link the help center auto-fills; the DB only stores the handle.
const SOCIAL_PLATFORMS = [
  {
    key: 'facebook',
    label: 'Facebook',
    icon: 'i-ri-facebook-circle-fill',
    prefix: 'facebook.com/',
  },
  { key: 'x', label: 'X', icon: 'i-ri-twitter-x-fill', prefix: 'x.com/' },
  {
    key: 'instagram',
    label: 'Instagram',
    icon: 'i-ri-instagram-fill',
    prefix: 'instagram.com/',
  },
  {
    key: 'linkedin',
    label: 'LinkedIn',
    icon: 'i-ri-linkedin-box-fill',
    prefix: 'linkedin.com/',
  },
  {
    key: 'youtube',
    label: 'YouTube',
    icon: 'i-ri-youtube-fill',
    prefix: 'youtube.com/',
  },
  {
    key: 'tiktok',
    label: 'TikTok',
    icon: 'i-ri-tiktok-fill',
    prefix: 'tiktok.com/',
  },
  {
    key: 'github',
    label: 'GitHub',
    icon: 'i-ri-github-fill',
    prefix: 'github.com/',
  },
  {
    key: 'whatsapp',
    label: 'WhatsApp',
    icon: 'i-ri-whatsapp-fill',
    prefix: 'wa.me/',
  },
];

const portalConfig = computed(() => props.activePortal?.config || {});

const state = reactive({
  layout: PORTAL_LAYOUTS.CLASSIC,
  socialProfiles: {},
});
const visiblePlatforms = ref([]);
const showAddMenu = ref(false);

let originalSnapshot = '';

const platformByKey = key => SOCIAL_PLATFORMS.find(p => p.key === key);

const trimmedHandle = key => (state.socialProfiles[key] || '').trim();

const buildSocialProfiles = () =>
  visiblePlatforms.value.reduce((acc, key) => {
    const handle = trimmedHandle(key);
    if (handle) acc[key] = handle;
    return acc;
  }, {});

const snapshot = () =>
  JSON.stringify({ layout: state.layout, social: buildSocialProfiles() });

const resetFromPortal = () => {
  const savedProfiles = portalConfig.value.social_profiles || {};
  state.layout = portalConfig.value.layout || PORTAL_LAYOUTS.CLASSIC;
  state.socialProfiles = SOCIAL_PLATFORMS.reduce((acc, { key }) => {
    acc[key] = savedProfiles[key] || '';
    return acc;
  }, {});
  visiblePlatforms.value = SOCIAL_PLATFORMS.map(p => p.key).filter(key =>
    (savedProfiles[key] || '').trim()
  );
  originalSnapshot = snapshot();
};

watch(() => props.activePortal, resetFromPortal, {
  immediate: true,
  deep: true,
});

const hasChanges = computed(() => snapshot() !== originalSnapshot);

const visiblePlatformDetails = computed(() =>
  visiblePlatforms.value.map(platformByKey)
);

const addablePlatforms = computed(() =>
  SOCIAL_PLATFORMS.filter(p => !visiblePlatforms.value.includes(p.key)).map(
    p => ({ label: p.label, value: p.key, action: p.key, icon: p.icon })
  )
);

const addPlatform = ({ value }) => {
  if (!visiblePlatforms.value.includes(value)) {
    visiblePlatforms.value.push(value);
  }
  showAddMenu.value = false;
};

const removePlatform = key => {
  visiblePlatforms.value = visiblePlatforms.value.filter(k => k !== key);
  state.socialProfiles[key] = '';
};

const handleSave = () => {
  emit('updatePortalConfiguration', {
    id: props.activePortal.id,
    slug: props.activePortal.slug,
    config: {
      layout: state.layout,
      social_profiles: buildSocialProfiles(),
    },
  });
};
</script>

<template>
  <div
    class="flex w-full flex-col gap-6 rounded-2xl border border-border/40 bg-card p-6 shadow-sm"
  >
    <div class="flex flex-col gap-2">
      <h6 class="text-base font-medium text-foreground">
        {{ t('HELP_CENTER.PORTAL_SETTINGS.LAYOUT_CONTENT.HEADER') }}
      </h6>
      <span class="text-sm text-muted-foreground">
        {{ t('HELP_CENTER.PORTAL_SETTINGS.LAYOUT_CONTENT.DESCRIPTION') }}
      </span>
    </div>

    <section class="flex flex-col gap-3">
      <div class="grid grid-cols-1 gap-3 text-muted-foreground sm:grid-cols-2">
        <RadioCard
          :id="PORTAL_LAYOUTS.CLASSIC"
          :is-active="state.layout === PORTAL_LAYOUTS.CLASSIC"
          :label="
            t('HELP_CENTER.PORTAL_SETTINGS.LAYOUT_CONTENT.LAYOUT.CLASSIC.TITLE')
          "
          :description="
            t(
              'HELP_CENTER.PORTAL_SETTINGS.LAYOUT_CONTENT.LAYOUT.CLASSIC.DESCRIPTION'
            )
          "
          @select="value => (state.layout = value)"
        >
          <div
            class="mt-2 w-full overflow-hidden rounded-md border border-border bg-muted/40"
          >
            <span v-dompurify-html="classicLayoutPreview" />
          </div>
        </RadioCard>

        <RadioCard
          :id="PORTAL_LAYOUTS.DOCUMENTATION"
          beta
          :is-active="state.layout === PORTAL_LAYOUTS.DOCUMENTATION"
          :label="
            t('HELP_CENTER.PORTAL_SETTINGS.LAYOUT_CONTENT.LAYOUT.SIDEBAR.TITLE')
          "
          :description="
            t(
              'HELP_CENTER.PORTAL_SETTINGS.LAYOUT_CONTENT.LAYOUT.SIDEBAR.DESCRIPTION'
            )
          "
          @select="value => (state.layout = value)"
        >
          <div
            class="mt-2 w-full overflow-hidden rounded-md border border-border bg-muted/40"
          >
            <span v-dompurify-html="documentationLayoutPreview" />
          </div>
        </RadioCard>
      </div>
    </section>

    <section
      v-if="state.layout === PORTAL_LAYOUTS.DOCUMENTATION"
      class="flex flex-col gap-3"
    >
      <div class="flex flex-col gap-1">
        <h6 class="text-sm font-medium text-foreground">
          {{
            t('HELP_CENTER.PORTAL_SETTINGS.LAYOUT_CONTENT.SOCIAL_LINKS.HEADER')
          }}
        </h6>
        <span class="text-sm text-muted-foreground">
          {{
            t(
              'HELP_CENTER.PORTAL_SETTINGS.LAYOUT_CONTENT.SOCIAL_LINKS.DESCRIPTION'
            )
          }}
        </span>
      </div>

      <div
        v-for="platform in visiblePlatformDetails"
        :key="platform.key"
        class="flex h-10 items-center gap-1.5 rounded-md border border-input px-3 shadow-xs focus-within:ring-1 focus-within:ring-ring"
      >
        <Icon
          :icon="platform.icon"
          class="size-4 shrink-0 text-muted-foreground"
        />
        <span class="shrink-0 text-sm text-muted-foreground">{{
          platform.prefix
        }}</span>
        <input
          v-model="state.socialProfiles[platform.key]"
          type="text"
          class="min-w-0 flex-1 bg-transparent text-sm text-foreground outline-none placeholder:text-muted-foreground"
          :placeholder="
            t(
              'HELP_CENTER.PORTAL_SETTINGS.LAYOUT_CONTENT.SOCIAL_LINKS.PLACEHOLDER'
            )
          "
        />
        <RelayButton
          variant="ghost"
          size="icon"
          class="size-7 text-muted-foreground"
          :aria-label="
            t('HELP_CENTER.PORTAL_SETTINGS.LAYOUT_CONTENT.SOCIAL_LINKS.REMOVE')
          "
          @click="removePlatform(platform.key)"
        >
          <span class="i-lucide-x size-3.5" />
        </RelayButton>
      </div>

      <div
        v-if="addablePlatforms.length"
        v-on-clickaway="() => (showAddMenu = false)"
        class="relative"
      >
        <RelayButton
          variant="outline"
          size="sm"
          class="h-8"
          @click="showAddMenu = !showAddMenu"
        >
          <span class="i-lucide-plus size-3.5" />
          {{ t('HELP_CENTER.PORTAL_SETTINGS.LAYOUT_CONTENT.SOCIAL_LINKS.ADD') }}
        </RelayButton>
        <DropdownMenu
          v-if="showAddMenu"
          :menu-items="addablePlatforms"
          class="top-full mt-1 w-52 ltr:left-0 rtl:right-0"
          @action="addPlatform"
        />
      </div>
    </section>

    <div class="flex justify-end border-t border-border/40 pt-5">
      <RelayButton
        class="h-9 shadow-xs"
        :disabled="!hasChanges || isFetching"
        @click="handleSave"
      >
        {{ t('HELP_CENTER.PORTAL_SETTINGS.LAYOUT_CONTENT.SAVE') }}
      </RelayButton>
    </div>
  </div>
</template>
