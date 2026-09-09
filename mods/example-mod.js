export default function registerExampleMod(api) {
  api.registerBlock({
    id: "marble",
    name: "Marbre",
    solid: true,
    mineTime: 0.8,
    texture: (x, y, noise) => {
      const vein = Math.abs(Math.sin((x * 1.7 + y * 2.4 + noise * 9) * 0.9));
      const base = 188 + Math.floor(vein * 44);
      return [base, base + 2, base + 6];
    }
  });

  api.addHotbarBlock("marble", 8);
}
