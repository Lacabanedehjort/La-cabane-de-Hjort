import type { Config } from "tailwindcss";

const config: Config = {
  content: ["./src/**/*.{js,ts,jsx,tsx,mdx}"],
  theme: {
    extend: {
      colors: {
        bois: {
          DEFAULT: "#836435",
          dark: "#5c4624",
          light: "#b08d5e",
        },
      },
      fontFamily: {
        viking: ["Georgia", "serif"],
      },
    },
  },
  plugins: [],
};

export default config;
