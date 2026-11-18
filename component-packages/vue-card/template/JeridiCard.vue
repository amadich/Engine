<script setup lang="ts">
defineProps<{ title: string; description?: string }>();
</script>
<template>
  <article class="jeridi-card">
    <h2>{{ title }}</h2>
    <p v-if="description">{{ description }}</p>
    <slot />
  </article>
</template>
<style scoped>
.jeridi-card { padding: 1.5rem; border: 1px solid #51597b; border-radius: 14px; }
</style>
