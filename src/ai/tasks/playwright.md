---
applies_to: Projects using Playwright Component Testing (playwright-ct)
skip_if: Not using Playwright Component Testing
---

# Playwright Component Testing

Tests run in Node.js while components run in a real browser. Components get real clicks, real layout, and visual regression support.

## Limitations

**You can't pass complex live objects to your component.** Only plain JavaScript objects and built-in types can be passed.

```typescript
test('this will work', async ({ mount }) => {
  const component = await mount(<ProcessViewer process={{ name: 'playwright' }}/>);
});
```

**You can't pass data synchronously via callbacks:**

```typescript
test('this will not work', async ({ mount }) => {
  const component = await mount(<ColorPicker colorGetter={() => 'red'}/>);
});
```

**Workaround:** Create test-specific wrapper components.

