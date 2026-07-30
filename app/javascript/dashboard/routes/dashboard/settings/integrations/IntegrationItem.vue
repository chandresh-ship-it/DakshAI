<script setup>
import { computed } from 'vue';
import { useStoreGetters } from 'dashboard/composables/store';
import { useI18n } from 'vue-i18n';
import { frontendURL } from 'dashboard/helper/URLHelper';
import { useBranding } from 'shared/composables/useBranding';

import { RelayButton, RelayBadge } from 'dashboard/components-next/relay';

const props = defineProps({
  id: {
    type: [String, Number],
    required: true,
  },
  name: {
    type: String,
    default: '',
  },
  description: {
    type: String,
    default: '',
  },
  enabled: {
    type: Boolean,
    default: false,
  },
});

const getters = useStoreGetters();
const accountId = getters.getCurrentAccountId;

const { t } = useI18n();
const { replaceInstallationName } = useBranding();

const integrationStatus = computed(() =>
  props.enabled
    ? t('INTEGRATION_APPS.STATUS.ENABLED')
    : t('INTEGRATION_APPS.STATUS.DISABLED')
);

const actionURL = computed(() =>
  frontendURL(`accounts/${accountId.value}/settings/integrations/${props.id}`)
);
</script>

<template>
  <div
    class="flex flex-col justify-between rounded-xl border border-border/60 bg-card p-5 transition-colors hover:border-border"
  >
    <div class="flex items-start gap-4">
      <div
        class="flex size-[52px] shrink-0 items-center justify-center overflow-hidden rounded-xl border border-border/60 bg-background shadow-sm"
      >
        <img
          :src="`/dashboard/images/integrations/${id}.png`"
          class="size-7 rounded-md block dark:hidden"
          :alt="name"
        />
        <img
          :src="`/dashboard/images/integrations/${id}-dark.png`"
          class="size-7 rounded-md hidden dark:block"
          :alt="name"
        />
      </div>
      <div class="min-w-0 flex-1 pt-0.5">
        <div class="flex items-center justify-between gap-2">
          <h4 class="text-[15px] font-bold leading-none text-foreground">
            {{ name }}
          </h4>
          <RelayBadge
            :variant="enabled ? 'default' : 'secondary'"
            class="shrink-0 text-[10px] uppercase"
          >
            {{ integrationStatus }}
          </RelayBadge>
        </div>
        <p class="mt-2 text-[13px] leading-relaxed text-muted-foreground">
          {{ replaceInstallationName(description) }}
        </p>
      </div>
    </div>
    <div
      class="mt-6 flex items-center justify-between border-t border-border/40 pt-4"
    >
      <router-link :to="actionURL">
        <RelayButton
          variant="outline"
          size="sm"
          class="h-8 px-4 text-xs font-semibold"
        >
          {{ $t('INTEGRATION_APPS.CONFIGURE') }}
        </RelayButton>
      </router-link>
    </div>
  </div>
</template>
