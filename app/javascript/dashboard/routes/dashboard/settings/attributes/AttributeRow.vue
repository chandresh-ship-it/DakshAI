<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import Icon from 'dashboard/components-next/icon/Icon.vue';
import { RelayButton, RelayBadge } from 'dashboard/components-next/relay';

const props = defineProps({
  attribute: {
    type: Object,
    required: true,
  },
  badges: {
    type: Array,
    default: () => [],
  },
  loading: {
    type: Boolean,
    default: false,
  },
});

const emit = defineEmits(['edit', 'delete']);
const { t } = useI18n();

const typeLabel = computed(() => {
  const typeKey = (props.attribute.type || '').toLowerCase();
  const labels = {
    text: t('ATTRIBUTES_MGMT.ATTRIBUTE_TYPES.TEXT'),
    number: t('ATTRIBUTES_MGMT.ATTRIBUTE_TYPES.NUMBER'),
    link: t('ATTRIBUTES_MGMT.ATTRIBUTE_TYPES.LINK'),
    date: t('ATTRIBUTES_MGMT.ATTRIBUTE_TYPES.DATE'),
    list: t('ATTRIBUTES_MGMT.ATTRIBUTE_TYPES.LIST'),
    checkbox: t('ATTRIBUTES_MGMT.ATTRIBUTE_TYPES.CHECKBOX'),
  };
  return labels[typeKey] || props.attribute.type;
});

const metaLine = computed(() => {
  const parts = [props.attribute.value, typeLabel.value].filter(Boolean);
  return parts.join(' • ');
});
</script>

<template>
  <div
    class="group flex items-center justify-between gap-4 p-4 transition-colors hover:bg-muted/20"
  >
    <div class="flex min-w-0 items-center gap-4">
      <div
        class="flex size-10 shrink-0 items-center justify-center rounded-lg bg-primary/10"
      >
        <Icon icon="i-lucide-code" class="size-5 text-primary" />
      </div>
      <div class="min-w-0">
        <div class="flex min-w-0 flex-wrap items-center gap-2">
          <h4 class="truncate text-[14px] font-semibold text-foreground">
            {{ attribute.label }}
          </h4>
          <RelayBadge
            v-for="badge in badges"
            :key="badge.type"
            variant="secondary"
            class="text-[11px]"
          >
            {{
              badge.type === 'pre-chat'
                ? t('ATTRIBUTES_MGMT.BADGES.PRE_CHAT')
                : t('ATTRIBUTES_MGMT.BADGES.RESOLUTION')
            }}
          </RelayBadge>
        </div>
        <p class="mt-0.5 truncate text-[13px] text-muted-foreground">
          {{ metaLine }}
        </p>
      </div>
    </div>

    <div class="flex shrink-0 items-center gap-1">
      <RelayButton
        variant="outline"
        size="sm"
        class="h-8 border-border bg-card px-3 text-[13px] shadow-xs hover:bg-muted"
        :disabled="loading"
        @click="emit('edit', attribute)"
      >
        {{ t('ATTRIBUTES_MGMT.LIST.BUTTONS.EDIT') }}
      </RelayButton>
      <RelayButton
        v-tooltip.top="t('ATTRIBUTES_MGMT.LIST.BUTTONS.DELETE')"
        variant="ghost"
        size="icon"
        class="size-8 border border-transparent text-muted-foreground shadow-xs hover:border-red-100 hover:bg-red-50 hover:text-red-600"
        :disabled="loading"
        @click="emit('delete', attribute)"
      >
        <Icon icon="i-lucide-trash-2" class="size-3.5" />
      </RelayButton>
    </div>
  </div>
</template>
