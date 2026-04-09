---
applies_to: Projects using Playwright Component Testing (playwright-ct)
skip_if: Not using Playwright Component Testing
---

# Playwright Component Testing

Tests run in Node.js while components run in a real browser. Components get real clicks, real layout, and visual regression support, while tests can use Playwright Test features (parallel, parametrized tests, post-mortem tracing, etc.).

## Limitations

**You can't pass complex live objects to your component.** Only plain JavaScript objects and built-in types (strings, numbers, dates, etc.) can be passed.

```typescript
test('this will work', async ({ mount }) => {
  const component = await mount(<ProcessViewer process={{ name: 'playwright' }}/>);
});

test('this will not work', async ({ mount }) => {
  // `process` is a Node object, can't pass to browser.
  const component = await mount(<ProcessViewer process={process}/>);
});
```

**You can't pass data synchronously via callbacks:**

```typescript
test('this will not work', async ({ mount }) => {
  // () => 'red' lives in Node. Browser component can't call it synchronously.
  const component = await mount(<ColorPicker colorGetter={() => 'red'}/>);
});
```

**Workaround:** Create test-specific wrapper components. This also provides powerful abstractions for controlling environment, theme, and other rendering context.
