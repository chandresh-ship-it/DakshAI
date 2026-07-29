<script setup>
import { isVNode, computed } from 'vue';
import Icon from 'next/icon/Icon.vue';
import Policy from 'dashboard/components/policy.vue';
import { useSidebarContext } from './provider';
import SidebarUnreadBadge from './SidebarUnreadBadge.vue';

const props = defineProps({
  label: { type: String, required: true },
  to: { type: [String, Object], required: true },
  icon: { type: [String, Object], default: null },
  active: { type: Boolean, default: false },
  component: { type: Function, default: null },
  badgeCount: { type: [Number, String], default: 0 },
});

const { resolvePermissions, resolveFeatureFlag } = useSidebarContext();

const shouldRenderComponent = computed(() => {
  return typeof props.component === 'function' || isVNode(props.component);
});
</script>

<!-- eslint-disable-next-line vue/no-root-v-if -->
<template>
  <Policy
    :permissions="resolvePermissions(to)"
    :feature-flag="resolveFeatureFlag(to)"
    as="li"
    class="group/menu-sub-item relative min-w-0"
  >
    <component
      :is="to ? 'router-link' : 'div'"
      :to="to"
      :title="label"
      class="flex h-8 min-w-0 items-center gap-3 overflow-hidden rounded-md px-2 text-sm outline-none transition-colors"
      :class="{
        'font-medium text-n-brand': active,
        'text-n-slate-11 hover:bg-n-alpha-2 hover:text-n-slate-12': !active,
      }"
    >
      <component
        :is="component"
        v-if="shouldRenderComponent"
        v-bind="{ label, icon, active, badgeCount }"
      />
      <template v-else>
        <span v-if="icon" class="grid size-4 shrink-0 place-content-center">
          <Icon :icon="icon" class="inline-block size-4" />
        </span>
        <div class="min-w-0 flex-1 truncate">{{ label }}</div>
        <SidebarUnreadBadge :count="badgeCount" />
      </template>
    </component>
  </Policy>
</template>
