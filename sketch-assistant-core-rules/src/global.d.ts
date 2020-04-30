declare module '@lingui/macro' {
  function t(strs: TemplateStringsArray, ...values: any[]): string

  function t(id: string): (strs: TemplateStringsArray, ...values: any[]) => string

  const plural: (ops: { value: number; one: string; other: string }) => string

  export { t, plural }
}

declare module '@lingui/core' {
  class I18n {
    public _(key: string, values?: any, options?: any): string

    public use(locale: string): I18n

    public activate(locale: string): void
  }

  const setupI18n: (ops: any) => I18n

  export { I18n, setupI18n }
}
