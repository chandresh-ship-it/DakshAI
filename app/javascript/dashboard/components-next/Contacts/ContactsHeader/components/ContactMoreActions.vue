<script setup>
import { computed, ref } from 'vue';
import { useI18n } from 'vue-i18n';

import { RelayButton } from 'dashboard/components-next/relay';
import DropdownMenu from 'dashboard/components-next/dropdown-menu/DropdownMenu.vue';
import { usePolicy } from 'dashboard/composables/usePolicy';

const emit = defineEmits(['add', 'import', 'export']);

const { t } = useI18n();
const { checkPermissions } = usePolicy();

const contactMenuItems = computed(() => [
  {
    label: t('CONTACTS_LAYOUT.HEADER.ACTIONS.CONTACT_CREATION.ADD_CONTACT'),
    action: 'add',
    value: 'add',
    icon: 'i-lucide-plus',
  },
  ...(checkPermissions(['administrator', 'contact_manage'])
    ? [
        {
          label: t(
            'CONTACTS_LAYOUT.HEADER.ACTIONS.CONTACT_CREATION.EXPORT_CONTACT'
          ),
          action: 'export',
          value: 'export',
          icon: 'i-lucide-upload',
        },
      ]
    : []),
  ...(checkPermissions(['administrator', 'contact_manage'])
    ? [
        {
          label: t(
            'CONTACTS_LAYOUT.HEADER.ACTIONS.CONTACT_CREATION.IMPORT_CONTACT'
          ),
          action: 'import',
          value: 'import',
          icon: 'i-lucide-download',
        },
      ]
    : []),
]);
const showActionsDropdown = ref(false);

const handleContactAction = ({ action }) => {
  if (action === 'add') {
    emit('add');
  } else if (action === 'import') {
    emit('import');
  } else if (action === 'export') {
    emit('export');
  }
};
</script>

<template>
  <div v-on-clickaway="() => (showActionsDropdown = false)" class="relative">
    <RelayButton
      variant="ghost"
      size="icon"
      class="size-8"
      :class="showActionsDropdown ? 'bg-n-alpha-2' : ''"
      @click="showActionsDropdown = !showActionsDropdown"
    >
      <span class="i-lucide-ellipsis-vertical size-4" />
    </RelayButton>
    <DropdownMenu
      v-if="showActionsDropdown"
      :menu-items="contactMenuItems"
      class="ltr:right-0 rtl:left-0 mt-1 w-52 top-full"
      @action="handleContactAction($event)"
    />
  </div>
</template>
