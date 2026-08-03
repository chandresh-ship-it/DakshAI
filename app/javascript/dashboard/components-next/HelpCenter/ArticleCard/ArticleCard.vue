<script setup>
import { computed } from 'vue';
import { useToggle } from '@vueuse/core';
import { useI18n } from 'vue-i18n';
import { dynamicTime } from 'shared/helpers/timeHelper';
import {
  ARTICLE_MENU_ITEMS,
  ARTICLE_MENU_OPTIONS,
  ARTICLE_STATUSES,
} from 'dashboard/helper/portalHelper';

import { useMapGetter } from 'dashboard/composables/store.js';
import { useConfig } from 'dashboard/composables/useConfig';
import { FEATURE_FLAGS } from 'dashboard/featureFlags';
import Icon from 'dashboard/components-next/icon/Icon.vue';
import DropdownMenu from 'dashboard/components-next/dropdown-menu/DropdownMenu.vue';
import Avatar from 'dashboard/components-next/avatar/Avatar.vue';
import { RelayButton, RelayCheckbox } from 'dashboard/components-next/relay';

const props = defineProps({
  id: {
    type: Number,
    required: true,
  },
  title: {
    type: String,
    required: true,
  },
  status: {
    type: String,
    required: true,
  },
  author: {
    type: Object,
    default: null,
  },
  category: {
    type: Object,
    required: true,
  },
  views: {
    type: Number,
    required: true,
  },
  updatedAt: {
    type: Number,
    required: true,
  },
  isSelected: {
    type: Boolean,
    default: false,
  },
  selectable: {
    type: Boolean,
    default: false,
  },
  showSelectionControl: {
    type: Boolean,
    default: false,
  },
});

const emit = defineEmits([
  'openArticle',
  'articleAction',
  'toggleSelect',
  'hover',
]);

const { t } = useI18n();

const [showActionsDropdown, toggleDropdown] = useToggle();

const currentAccountId = useMapGetter('getCurrentAccountId');
const isFeatureEnabledonAccount = useMapGetter(
  'accounts/isFeatureEnabledonAccount'
);
const { isEnterprise } = useConfig();

const isTranslationAvailable = computed(
  () =>
    isEnterprise &&
    isFeatureEnabledonAccount.value(
      currentAccountId.value,
      FEATURE_FLAGS.CAPTAIN_TASKS
    )
);

const articleMenuItems = computed(() => {
  const commonItems = Object.entries(ARTICLE_MENU_ITEMS).reduce(
    (acc, [key, item]) => {
      acc[key] = { ...item, label: t(item.label) };
      return acc;
    },
    {}
  );

  const statusItems = (
    ARTICLE_MENU_OPTIONS[props.status] ||
    ARTICLE_MENU_OPTIONS[ARTICLE_STATUSES.PUBLISHED]
  )
    .filter(key => key !== 'translate' || isTranslationAvailable.value)
    .map(key => commonItems[key]);

  return [...statusItems, commonItems.delete];
});

const statusBadgeClass = computed(() => {
  switch (props.status) {
    case 'archived':
      return 'bg-muted text-muted-foreground';
    case 'draft':
      return 'bg-amber-500/15 text-amber-600';
    default:
      return 'bg-primary/10 text-primary';
  }
});

const statusText = computed(() => {
  switch (props.status) {
    case 'archived':
      return t('HELP_CENTER.ARTICLES_PAGE.ARTICLE_CARD.CARD.STATUS.ARCHIVED');
    case 'draft':
      return t('HELP_CENTER.ARTICLES_PAGE.ARTICLE_CARD.CARD.STATUS.DRAFT');
    default:
      return t('HELP_CENTER.ARTICLES_PAGE.ARTICLE_CARD.CARD.STATUS.PUBLISHED');
  }
});

const categoryName = computed(() => {
  if (props.category?.slug) {
    return `${props.category.icon} ${props.category.name}`;
  }
  return t(
    'HELP_CENTER.ARTICLES_PAGE.ARTICLE_CARD.CARD.CATEGORY.UNCATEGORISED'
  );
});

const authorName = computed(() => {
  return props.author?.name || props.author?.availableName || '';
});

const authorThumbnailSrc = computed(() => {
  return props.author?.thumbnail;
});

const lastUpdatedAt = computed(() => {
  return dynamicTime(props.updatedAt);
});

const handleArticleAction = ({ action, value }) => {
  toggleDropdown(false);
  emit('articleAction', { action, value, id: props.id });
};

const handleClick = id => {
  emit('openArticle', id);
};
</script>

<template>
  <div
    class="group relative flex cursor-pointer flex-col justify-between gap-3 rounded-xl border p-5 transition-all sm:flex-row sm:items-center"
    :class="
      isSelected
        ? 'border-primary/60 bg-primary/5 shadow-sm'
        : 'border-border bg-card hover:shadow-sm'
    "
    @mouseenter="emit('hover', true)"
    @mouseleave="emit('hover', false)"
    @click="handleClick(id)"
  >
    <div class="flex min-w-0 flex-1 items-center gap-3 pr-4">
      <div
        v-show="selectable && showSelectionControl"
        class="shrink-0"
        @click.stop
      >
        <RelayCheckbox
          :model-value="isSelected"
          @update:model-value="emit('toggleSelect', id)"
        />
      </div>

      <div class="flex min-w-0 flex-1 flex-col gap-1.5">
        <h3
          class="truncate text-[15px] font-normal text-foreground transition-colors group-hover:text-primary"
        >
          {{ title }}
        </h3>

        <div
          class="flex flex-wrap items-center gap-3 text-[13px] text-muted-foreground"
        >
          <div class="flex items-center gap-1.5">
            <Avatar
              :name="authorName"
              :src="authorThumbnailSrc"
              :size="16"
              rounded-full
            />
            <span>{{ authorName || '-' }}</span>
          </div>
          <span class="text-[10px] text-muted-foreground/40">•</span>
          <span>{{ categoryName }}</span>
          <span class="text-[10px] text-muted-foreground/40">•</span>
          <div class="inline-flex items-center gap-1.5">
            <Icon icon="i-lucide-eye" class="size-3.5 opacity-60" />
            <span>
              {{
                t('HELP_CENTER.ARTICLES_PAGE.ARTICLE_CARD.CARD.VIEWS', {
                  count: views,
                })
              }}
            </span>
          </div>
        </div>
      </div>
    </div>

    <div class="flex shrink-0 flex-col items-end gap-1">
      <div class="flex items-center gap-1.5">
        <span
          class="rounded px-2 py-0.5 text-[12px] font-medium"
          :class="statusBadgeClass"
        >
          {{ statusText }}
        </span>
        <div
          v-on-clickaway="() => toggleDropdown(false)"
          class="relative"
          @click.stop
        >
          <RelayButton
            variant="ghost"
            size="icon"
            class="size-7 border border-transparent text-muted-foreground hover:border-transparent hover:bg-muted hover:text-foreground"
            @click="toggleDropdown()"
          >
            <span class="i-lucide-ellipsis-vertical size-3.5" />
          </RelayButton>
          <DropdownMenu
            v-if="showActionsDropdown"
            :menu-items="articleMenuItems"
            class="top-full mt-1 ltr:right-0 rtl:left-0 xl:ltr:left-0 xl:rtl:right-0"
            @action="handleArticleAction($event)"
          />
        </div>
      </div>
      <span class="text-right text-[12.5px] text-muted-foreground">
        {{ lastUpdatedAt }}
      </span>
    </div>
  </div>
</template>
