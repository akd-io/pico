const versions = [
  "0.1.0",
  "0.1.0b",
  "0.1.0c",
  "0.1.0d",
  "0.1.0e",
  "0.1.0f",
  "0.1.0g",
  "0.1.0h",
  "0.1.1",
  "0.1.1b",
  "0.1.1c",
  "0.1.1d",
  "0.1.1e",
  "0.1.1f",
  "0.2.0",
  "0.2.0b",
  "0.2.0c",
] as const;

type Version = (typeof versions)[number];

export type PatcherConfig = {
  patches: Array<{
    name: string;
    description: string;
    supportedVersions: Array<Version>;
    mods: Array<{
      hide?: {
        count: number;
        pattern: string;
      };
      replace?: {
        count: number;
        pattern: string;
        replacement: string;
      };
    }>;
    before?: string;
    requires?: string;
  }>;
};
