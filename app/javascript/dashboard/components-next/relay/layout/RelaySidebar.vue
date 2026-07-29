<script setup>
import { computed, ref, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import { cn } from '../utils/cn';

const props = defineProps({
  brandName: { type: String, default: 'newrelay' },
  collapsed: { type: Boolean, default: false },
  sections: {
    type: Array,
    default: () => [],
  },
  activeHref: { type: String, default: '' },
});

const emit = defineEmits(['update:collapsed', 'navigate']);
const { t } = useI18n();

const openGroup = ref(null);

const isActive = href => href && props.activeHref === href;

const itemHasActiveChild = item => {
  if (isActive(item.href)) return true;
  return Boolean(item.children?.some(child => isActive(child.href)));
};

watch(
  () => [props.sections, props.activeHref],
  () => {
    const active = props.sections
      .flatMap(section => section.items || [])
      .find(item => itemHasActiveChild(item));
    openGroup.value = active?.title ?? null;
  },
  { immediate: true, deep: true }
);

const toggleGroup = title => {
  openGroup.value = openGroup.value === title ? null : title;
};

const onNavigate = href => {
  if (href) emit('navigate', href);
};

const widthClass = computed(() => (props.collapsed ? 'w-16' : 'w-60'));
</script>

<template>
  <aside
    :class="
      cn(
        'flex h-full flex-col border-r border-n-weak bg-n-solid-1 text-n-slate-12 transition-[width] duration-200 ease-linear',
        widthClass
      )
    "
  >
    <div
      :class="
        cn(
          'flex h-14 items-center border-b border-n-weak px-3',
          collapsed ? 'justify-center' : 'justify-between gap-2'
        )
      "
    >
      <div
        :class="
          cn('flex min-w-0 items-center gap-2', collapsed && 'justify-center')
        "
      >
        <span
          class="flex size-8 shrink-0 items-center justify-center rounded-md bg-n-brand text-sm font-semibold text-white"
        >
          {{ brandName.slice(0, 1).toUpperCase() }}
        </span>
        <span
          v-if="!collapsed"
          class="truncate text-sm font-medium text-n-slate-12"
        >
          {{ brandName }}
        </span>
      </div>
      <button
        v-if="!collapsed"
        type="button"
        class="inline-flex size-8 items-center justify-center rounded-md text-n-slate-11 hover:bg-n-alpha-2 hover:text-n-slate-12"
        @click="emit('update:collapsed', true)"
      >
        <span class="i-lucide-panel-left size-4" />
        <span class="sr-only">{{ t('SIDEBAR.COLLAPSE_SIDEBAR') }}</span>
      </button>
    </div>

    <nav class="flex-1 overflow-y-auto px-2 py-3">
      <div
        v-for="(section, sectionIndex) in sections"
        :key="section.label || sectionIndex"
        class="mb-4"
      >
        <p
          v-if="section.label && !collapsed"
          class="mb-1 px-2 text-xs font-medium uppercase tracking-wide text-n-slate-11"
        >
          {{ section.label }}
        </p>

        <div v-for="item in section.items" :key="item.title" class="mb-0.5">
          <button
            type="button"
            :class="
              cn(
                'relative flex w-full items-center gap-3 rounded-md p-2 text-left text-sm transition-colors',
                'hover:bg-n-alpha-2',
                collapsed && 'justify-center',
                itemHasActiveChild(item) && 'font-medium text-n-brand'
              )
            "
            @click="
              item.children?.length
                ? toggleGroup(item.title)
                : onNavigate(item.href)
            "
          >
            <span v-if="item.icon" :class="cn(item.icon, 'size-4 shrink-0')" />
            <span v-if="!collapsed" class="min-w-0 flex-1 truncate">
              {{ item.title }}
            </span>
            <span
              v-if="!collapsed && item.children?.length"
              :class="
                cn(
                  'i-lucide-chevron-right size-4 shrink-0 text-n-slate-11 transition-transform',
                  openGroup === item.title && 'rotate-90'
                )
              "
            />
          </button>

          <div
            v-if="
              !collapsed && item.children?.length && openGroup === item.title
            "
            class="ml-2 mt-0.5 space-y-0.5 border-l border-n-weak pl-2"
          >
            <button
              v-for="child in item.children"
              :key="child.href || child.title"
              type="button"
              :class="
                cn(
                  'flex h-8 w-full items-center rounded-md px-2 text-left text-sm transition-colors',
                  'hover:bg-n-alpha-2',
                  isActive(child.href)
                    ? 'font-medium text-n-brand'
                    : 'text-n-slate-11'
                )
              "
              @click="onNavigate(child.href)"
            >
              <span class="truncate">{{ child.title }}</span>
            </button>
          </div>
        </div>
      </div>
    </nav>

    <div v-if="collapsed" class="border-t border-n-weak p-2">
      <button
        type="button"
        class="inline-flex size-10 w-full items-center justify-center rounded-md text-n-slate-11 hover:bg-n-alpha-2"
        @click="emit('update:collapsed', false)"
      >
        <span class="i-lucide-panel-left size-4" />
        <span class="sr-only">{{ t('SIDEBAR.EXPAND_SIDEBAR') }}</span>
      </button>
    </div>
  </aside>
</template>
