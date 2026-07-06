<script setup>
import { ref, computed, onMounted, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import { useStore, useMapGetter } from 'dashboard/composables/store';
import Button from 'dashboard/components-next/button/Button.vue';
import Checkbox from 'dashboard/components-next/checkbox/Checkbox.vue';
import ComboBox from 'dashboard/components-next/combobox/ComboBox.vue';
import Input from 'dashboard/components-next/input/Input.vue';
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';
import Dialog from 'dashboard/components-next/dialog/Dialog.vue';
import Avatar from 'dashboard/components-next/avatar/Avatar.vue';
import TasksAPI from 'dashboard/api/tasks';

const { t } = useI18n();
const store = useStore();

const tasks = ref([]);
const isFetching = ref(false);
const searchQuery = ref('');
const activeTab = ref('all');

const assigneeFilter = ref('any');
const statusFilter = ref('all');
const dueDateFilter = ref('any');

const taskDialogRef = ref(null);
const editingTask = ref(null);
const taskForm = ref({
  title: '',
  description: '',
  assigneeId: '',
  contactId: '',
  dueDate: '',
});

const agents = useMapGetter('agents/getAgents');
const contacts = useMapGetter('contacts/getContactsList');

const agentOptions = computed(() => {
  const list = (agents.value || []).map(agent => ({
    label: agent.name,
    value: agent.id.toString(),
  }));
  return [{ label: 'Unassigned', value: '' }, ...list];
});

const assigneeFilterOptions = computed(() => {
  const list = (agents.value || []).map(agent => ({
    label: agent.name,
    value: agent.id.toString(),
  }));
  return [{ label: 'Assignee: Any', value: 'any' }, ...list];
});

const statusFilterOptions = [
  { label: 'Status: All', value: 'all' },
  { label: 'Pending', value: 'pending' },
  { label: 'Completed', value: 'completed' },
];

const dueDateFilterOptions = [
  { label: 'Due Date: Any', value: 'any' },
  { label: 'Due today', value: 'today' },
  { label: 'Overdue', value: 'overdue' },
  { label: 'Upcoming', value: 'upcoming' },
];

const contactOptions = computed(() => {
  return (contacts.value || []).map(contact => ({
    label: contact.name || contact.email || 'Unnamed Contact',
    value: contact.id.toString(),
  }));
});

const fetchTasks = async () => {
  isFetching.value = true;
  try {
    const params = {
      q: searchQuery.value,
    };

    if (activeTab.value !== 'all') {
      params.due_filter = activeTab.value;
    } else if (dueDateFilter.value !== 'any') {
      params.due_filter = dueDateFilter.value;
    }

    if (assigneeFilter.value !== 'any') {
      params.assignee_id = assigneeFilter.value;
    }

    if (statusFilter.value !== 'all') {
      params.completed = statusFilter.value === 'completed';
    }

    const response = await TasksAPI.get(params);
    tasks.value = response.data;
  } catch (error) {
    // Ignore error
  } finally {
    isFetching.value = false;
  }
};

const getAgentName = id => {
  if (!id) return '';
  const agent = (agents.value || []).find(
    a => a.id.toString() === id.toString()
  );
  return agent ? agent.name : '';
};

const getAgentThumbnail = id => {
  if (!id) return '';
  const agent = (agents.value || []).find(
    a => a.id.toString() === id.toString()
  );
  return agent ? agent.thumbnail : '';
};

const formatDate = dateString => {
  if (!dateString) return '';
  const date = new Date(dateString);
  return date.toLocaleDateString(undefined, {
    month: 'short',
    day: 'numeric',
    year: 'numeric',
    hour: '2-digit',
    minute: '2-digit',
  });
};

const isOverdue = task => {
  if (task.completed) return false;
  return new Date(task.due_at) < new Date();
};

const toggleTaskStatus = async task => {
  const originalVal = task.completed;
  task.completed = !task.completed;
  try {
    await TasksAPI.update(task.id, { task: { completed: task.completed } });
  } catch (error) {
    task.completed = originalVal;
  }
};

const openAddTaskDialog = () => {
  editingTask.value = null;
  taskForm.value = {
    title: '',
    description: '',
    assigneeId: '',
    contactId: '',
    dueDate: '',
  };
  taskDialogRef.value.open();
};

const openEditTaskDialog = task => {
  editingTask.value = task;
  taskForm.value = {
    title: task.title,
    description: task.description || '',
    assigneeId: task.assignee_id ? task.assignee_id.toString() : '',
    contactId: task.contacts?.[0]?.id ? task.contacts[0].id.toString() : '',
    dueDate: task.due_at ? task.due_at.slice(0, 16) : '',
  };
  taskDialogRef.value.open();
};

const handleDeleteTask = async id => {
  if (window.confirm('Are you sure you want to delete this task?')) {
    try {
      await TasksAPI.delete(id);
      tasks.value = tasks.value.filter(taskItem => taskItem.id !== id);
    } catch {
      // Ignore error
    }
  }
};

const handleSaveTask = async () => {
  const payload = {
    task: {
      title: taskForm.value.title,
      description: taskForm.value.description,
      assignee_id: taskForm.value.assigneeId || null,
      due_at: taskForm.value.dueDate || null,
      contact_ids: taskForm.value.contactId
        ? [Number(taskForm.value.contactId)]
        : [],
    },
  };

  try {
    if (editingTask.value) {
      await TasksAPI.update(editingTask.value.id, payload);
    } else {
      await TasksAPI.create(payload);
    }
    fetchTasks();
    taskDialogRef.value.close();
  } catch {
    // Ignore error
  }
};

const setTab = tab => {
  activeTab.value = tab;
  dueDateFilter.value = tab === 'all' ? 'any' : tab;
  fetchTasks();
};

watch([assigneeFilter, statusFilter, dueDateFilter], () => {
  if (dueDateFilter.value !== 'any') {
    activeTab.value = dueDateFilter.value;
  } else {
    activeTab.value = 'all';
  }
  fetchTasks();
});

watch(searchQuery, () => {
  fetchTasks();
});

onMounted(() => {
  store.dispatch('agents/get');
  store.dispatch('contacts/get', { page: 1 });
  fetchTasks();
});
</script>

<template>
  <div class="flex flex-col flex-1 h-full overflow-hidden bg-n-surface-1">
    <!-- Header -->
    <div
      class="flex items-center justify-between px-6 py-6 border-b border-n-slate-4 bg-n-surface-1"
    >
      <div class="flex items-center gap-3">
        <span class="text-xl font-medium text-n-slate-12">
          {{ t('CONTACTS_LAYOUT.TASKS_VIEW.TITLE') }}
        </span>
        <span
          class="px-2 py-0.5 text-xs font-semibold rounded-full bg-n-brand text-white"
        >
          {{
            t('CONTACTS_LAYOUT.TASKS_VIEW.TASKS_COUNT', {
              count: tasks.length,
            })
          }}
        </span>
      </div>
      <div class="flex items-center gap-2">
        <Button
          :label="t('CONTACTS_LAYOUT.TASKS_VIEW.ADD_TASK')"
          icon="i-lucide-plus"
          size="sm"
          @click="openAddTaskDialog"
        />
      </div>
    </div>

    <!-- Sub-tabs -->
    <div
      class="flex items-center justify-between border-b border-n-slate-4 bg-n-surface-2 px-6 py-2 shrink-0"
    >
      <div class="flex items-center gap-6">
        <button
          class="text-sm font-medium transition-colors hover:text-n-slate-12 px-1 py-1.5 relative cursor-pointer"
          :class="
            activeTab === 'all'
              ? 'text-n-slate-12 font-semibold'
              : 'text-n-slate-9'
          "
          @click="setTab('all')"
        >
          {{ t('CONTACTS_LAYOUT.TASKS_VIEW.TAB_ALL') }}
          <span
            v-if="activeTab === 'all'"
            class="absolute bottom-0 left-0 right-0 h-0.5 bg-n-brand rounded-full"
          />
        </button>
        <button
          class="text-sm font-medium transition-colors hover:text-n-slate-12 px-1 py-1.5 relative cursor-pointer"
          :class="
            activeTab === 'today'
              ? 'text-n-slate-12 font-semibold'
              : 'text-n-slate-9'
          "
          @click="setTab('today')"
        >
          {{ t('CONTACTS_LAYOUT.TASKS_VIEW.TAB_TODAY') }}
          <span
            v-if="activeTab === 'today'"
            class="absolute bottom-0 left-0 right-0 h-0.5 bg-n-brand rounded-full"
          />
        </button>
        <button
          class="text-sm font-medium transition-colors hover:text-n-slate-12 px-1 py-1.5 relative cursor-pointer"
          :class="
            activeTab === 'overdue'
              ? 'text-n-slate-12 font-semibold'
              : 'text-n-slate-9'
          "
          @click="setTab('overdue')"
        >
          {{ t('CONTACTS_LAYOUT.TASKS_VIEW.TAB_OVERDUE') }}
          <span
            v-if="activeTab === 'overdue'"
            class="absolute bottom-0 left-0 right-0 h-0.5 bg-n-brand rounded-full"
          />
        </button>
        <button
          class="text-sm font-medium transition-colors hover:text-n-slate-12 px-1 py-1.5 relative cursor-pointer"
          :class="
            activeTab === 'upcoming'
              ? 'text-n-slate-12 font-semibold'
              : 'text-n-slate-9'
          "
          @click="setTab('upcoming')"
        >
          {{ t('CONTACTS_LAYOUT.TASKS_VIEW.TAB_UPCOMING') }}
          <span
            v-if="activeTab === 'upcoming'"
            class="absolute bottom-0 left-0 right-0 h-0.5 bg-n-brand rounded-full"
          />
        </button>
        <button
          class="text-sm font-medium text-n-brand hover:underline flex items-center gap-1 cursor-pointer"
        >
          <span class="text-sm">+</span>
          {{ t('CONTACTS_LAYOUT.TASKS_VIEW.ADD_LIST') }}
        </button>
      </div>
    </div>

    <!-- Filters Row -->
    <div
      class="flex items-center justify-between border-b border-n-slate-4 bg-n-surface-1 px-6 py-3.5 shrink-0 gap-4"
    >
      <div class="flex items-center gap-3">
        <ComboBox
          v-model="assigneeFilter"
          :options="assigneeFilterOptions"
          placeholder="Assignee"
          class="min-w-[140px] [&>div>button]:h-8"
        />
        <ComboBox
          v-model="statusFilter"
          :options="statusFilterOptions"
          placeholder="Status"
          class="min-w-[120px] [&>div>button]:h-8"
        />
        <ComboBox
          v-model="dueDateFilter"
          :options="dueDateFilterOptions"
          placeholder="Due Date"
          class="min-w-[140px] [&>div>button]:h-8"
        />
        <Button
          label="Advanced filters"
          icon="i-lucide-list-filter"
          variant="ghost"
          color="slate"
          size="sm"
        />
        <Button
          label="Sort"
          icon="i-lucide-arrow-up-down"
          variant="ghost"
          color="slate"
          size="sm"
        />
      </div>

      <div class="flex items-center gap-4">
        <div class="relative w-64">
          <Input
            v-model="searchQuery"
            type="search"
            placeholder="Search for task title"
            custom-input-class="h-8 [&:not(.focus)]:!border-transparent bg-n-alpha-2 dark:bg-n-solid-1 ltr:!pl-8 !py-1 rtl:!pr-8 w-full"
          >
            <template #prefix>
              <span
                class="i-lucide-search absolute -translate-y-1/2 text-n-slate-11 size-4 top-1/2 ltr:left-2"
              />
            </template>
          </Input>
        </div>
        <button
          class="text-sm font-semibold text-n-slate-11 hover:text-n-slate-12 flex items-center gap-1 cursor-pointer"
        >
          <span class="i-lucide-settings size-4" />
          {{ t('CONTACTS_LAYOUT.TASKS_VIEW.MANAGE_FIELDS') }}
        </button>
      </div>
    </div>

    <!-- Data Table -->
    <div class="flex-1 overflow-auto p-6">
      <div v-if="isFetching" class="flex items-center justify-center h-48">
        <Spinner />
      </div>
      <div
        v-else-if="!tasks.length"
        class="flex flex-col items-center justify-center h-48 border border-dashed rounded-lg border-n-slate-4"
      >
        <span class="text-n-slate-11 text-sm">
          {{ t('CONTACTS_LAYOUT.TASKS_VIEW.NO_TASKS') }}
        </span>
      </div>
      <div
        v-else
        class="w-full border rounded-lg border-n-slate-4 bg-n-surface-1"
      >
        <table class="w-full text-left border-collapse table-auto">
          <thead>
            <tr
              class="border-b border-n-slate-4 bg-n-slate-2 text-n-slate-11 text-xs font-semibold uppercase tracking-wider"
            >
              <th class="p-3 w-10 text-center">
                <Checkbox />
              </th>
              <th
                class="p-3 text-sm font-semibold capitalize text-n-slate-12 w-20"
              >
                {{ t('CONTACTS_LAYOUT.TASKS_VIEW.COL_STATUS') }}
              </th>
              <th
                class="p-3 text-sm font-semibold capitalize text-n-slate-12 w-1/4"
              >
                {{ t('CONTACTS_LAYOUT.TASKS_VIEW.COL_TITLE') }}
              </th>
              <th
                class="p-3 text-sm font-semibold capitalize text-n-slate-12 w-1/4"
              >
                {{ t('CONTACTS_LAYOUT.TASKS_VIEW.COL_DESCRIPTION') }}
              </th>
              <th class="p-3 text-sm font-semibold capitalize text-n-slate-12">
                {{ t('CONTACTS_LAYOUT.TASKS_VIEW.COL_CONTACTS') }}
              </th>
              <th class="p-3 text-sm font-semibold capitalize text-n-slate-12">
                {{ t('CONTACTS_LAYOUT.TASKS_VIEW.COL_ASSIGNEE') }}
              </th>
              <th class="p-3 text-sm font-semibold capitalize text-n-slate-12">
                {{ t('CONTACTS_LAYOUT.TASKS_VIEW.COL_DUE_DATE') }}
              </th>
              <th class="p-3 w-24 text-center">
                {{ t('CONTACTS_LAYOUT.TASKS_VIEW.COL_ACTIONS') }}
              </th>
            </tr>
          </thead>
          <tbody class="divide-y divide-n-slate-3 text-sm text-n-slate-12">
            <tr
              v-for="task in tasks"
              :key="task.id"
              class="hover:bg-n-slate-2 transition-colors"
            >
              <td class="p-3 text-center">
                <Checkbox />
              </td>
              <td class="p-3 text-center">
                <button
                  class="cursor-pointer size-5 flex items-center justify-center text-n-slate-9 hover:text-n-brand"
                  @click="toggleTaskStatus(task)"
                >
                  <span
                    :class="
                      task.completed
                        ? 'i-lucide-check-circle-2 text-green-600 size-5'
                        : 'i-lucide-circle size-5'
                    "
                  />
                </button>
              </td>
              <td class="p-3 font-medium">
                {{ task.title }}
              </td>
              <td class="p-3 text-n-slate-11">
                {{ task.description || '-' }}
              </td>
              <td class="p-3">
                <div
                  v-if="task.contacts && task.contacts.length"
                  class="flex items-center gap-2"
                >
                  <Avatar
                    :name="task.contacts[0].name"
                    :size="24"
                    hide-offline-status
                  />
                  <span>{{ task.contacts[0].name }}</span>
                </div>
                <span v-else>-</span>
              </td>
              <td class="p-3">
                <div v-if="task.assignee_id" class="flex items-center gap-2">
                  <Avatar
                    :name="getAgentName(task.assignee_id)"
                    :src="getAgentThumbnail(task.assignee_id)"
                    :size="24"
                    hide-offline-status
                  />
                  <span>{{ getAgentName(task.assignee_id) }}</span>
                </div>
                <span v-else>-</span>
              </td>
              <td class="p-3 font-medium">
                <span
                  :class="
                    isOverdue(task)
                      ? 'text-red-600 font-semibold'
                      : 'text-n-slate-11'
                  "
                >
                  {{ formatDate(task.due_at) || '-' }}
                </span>
              </td>
              <td class="p-3 text-center space-x-2">
                <Button
                  icon="i-lucide-pencil"
                  variant="ghost"
                  color="slate"
                  size="xs"
                  @click="openEditTaskDialog(task)"
                />
                <Button
                  icon="i-lucide-trash"
                  variant="ghost"
                  color="slate"
                  size="xs"
                  class="hover:text-red-600"
                  @click="handleDeleteTask(task.id)"
                />
              </td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>

    <!-- Task CRUD Dialog -->
    <Dialog
      ref="taskDialogRef"
      :title="
        editingTask
          ? t('CONTACTS_LAYOUT.TASKS_VIEW.EDIT_TASK')
          : t('CONTACTS_LAYOUT.TASKS_VIEW.ADD_TASK')
      "
      @confirm="handleSaveTask"
    >
      <div class="space-y-4 pt-4">
        <div>
          <label class="block text-sm font-semibold text-n-slate-12 mb-1">
            {{ t('CONTACTS_LAYOUT.TASKS_VIEW.FORM_TITLE') }}
          </label>
          <Input
            v-model="taskForm.title"
            placeholder="Enter task title"
            class="w-full"
          />
        </div>
        <div>
          <label class="block text-sm font-semibold text-n-slate-12 mb-1">
            {{ t('CONTACTS_LAYOUT.TASKS_VIEW.FORM_DESCRIPTION') }}
          </label>
          <textarea
            v-model="taskForm.description"
            placeholder="Enter task description"
            class="w-full min-h-[80px] p-2 text-sm border rounded-lg border-n-slate-4 bg-transparent text-n-slate-12 outline-none focus:border-n-brand"
          />
        </div>
        <div class="grid grid-cols-2 gap-4">
          <div>
            <label class="block text-sm font-semibold text-n-slate-12 mb-1">
              {{ t('CONTACTS_LAYOUT.TASKS_VIEW.FORM_ASSIGNEE') }}
            </label>
            <ComboBox
              v-model="taskForm.assigneeId"
              :options="agentOptions"
              placeholder="Select assignee"
              class="w-full [&>div>button]:h-10"
            />
          </div>
          <div>
            <label class="block text-sm font-semibold text-n-slate-12 mb-1">
              {{ t('CONTACTS_LAYOUT.TASKS_VIEW.FORM_CONTACT') }}
            </label>
            <ComboBox
              v-model="taskForm.contactId"
              :options="contactOptions"
              placeholder="Select contact"
              class="w-full [&>div>button]:h-10"
            />
          </div>
        </div>
        <div>
          <label class="block text-sm font-semibold text-n-slate-12 mb-1">
            {{ t('CONTACTS_LAYOUT.TASKS_VIEW.FORM_DUE_DATE') }}
          </label>
          <input
            v-model="taskForm.dueDate"
            type="datetime-local"
            class="w-full h-10 px-3 text-sm border rounded-lg border-n-slate-4 bg-transparent text-n-slate-12 outline-none focus:border-n-brand"
          />
        </div>
      </div>
    </Dialog>
  </div>
</template>
