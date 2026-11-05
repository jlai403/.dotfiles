import { View, div } from "gpui-kit";
import { v_flex, h_flex } from "gpui-base";
import { home, readTextFile, theme } from "herdr";

const USAGE_URL = "https://opencode.ai/zen/go/v1/usage";
const AUTH_PATH = `${home()}/.local/share/opencode/auth.json`;
const WINDOWS = ["rolling", "weekly", "monthly"];
const LABELS = { rolling: "5h window", weekly: "Weekly", monthly: "Monthly" };

const barColor = (pct, limited, t) =>
  limited || pct >= 85 ? t.ansi1 : pct >= 60 ? t.ansi3 : t.ansi2;

const countdown = (iso) => {
  const ms = Date.parse(iso) - Date.now();
  if (!Number.isFinite(ms)) return "";
  if (ms <= 0) return "resets any moment";
  const minutes = Math.ceil(ms / 60000);
  if (minutes < 60) return `resets in ${minutes}m`;
  const days = Math.floor(minutes / 1440), hours = Math.floor((minutes % 1440) / 60);
  if (days) return `resets in ${days}d ${hours}h`;
  return `resets in ${hours}h ${(minutes % 60)}m`;
};

export default class Usage extends View {
  init(_props, cx) {
    this.windows = null;
    this.error = null;
    this.loading = false;
    this.bars = {};
    this.refresh(cx);
    cx.timer.every(60000, (cx) => this.refresh(cx));
  }

  refresh(cx) {
    if (this.loading) return;
    this.loading = true;
    cx.spawn(async (cx) => {
      try {
        const text = await readTextFile(AUTH_PATH);
        const key = text && JSON.parse(text)["opencode-go"]?.key;
        if (!key) {
          this.windows = null;
          this.error = "No OpenCode Go key — run: opencode auth login -p opencode-go";
          return;
        }
        const res = await fetch(USAGE_URL, { headers: { Authorization: `Bearer ${key}` } });
        if (!res.ok) {
          this.windows = null;
          this.error = `Usage API error ${res.status}`;
          return;
        }
        const body = await res.json();
        // The endpoint wraps its windows in a top-level "usage" object.
        const root = body?.usage ?? body;
        const windows = {};
        let malformed = null;
        for (const w of WINDOWS) {
          const win = root?.[w];
          if (win && typeof win.percent === "number" && typeof win.resetsAt === "string") {
            windows[w] = { pct: Math.round(win.percent), limited: win.status === "rate-limited", resetsAt: win.resetsAt };
          } else malformed = w;
        }
        if (malformed) throw new Error(`Usage API: malformed "${malformed}" window`);
        this.windows = windows;
        this.error = null;
      } catch (e) {
        this.windows = null;
        this.error = String(e).replace(/^Error: /, "");
      } finally {
        this.loading = false;
        cx.notify();
      }
    });
  }

  track(key) {
    return div().id(`usage-bar-${key}`).flex_1().min_w(0).h(6).relative().rounded(3).bg(theme().hover)
      .on_size_change((size, cx) => {
        if (this.bars[key] !== size.width) { this.bars[key] = size.width; cx.notify(); }
      });
  }

  row(key, w, t) {
    const fill = Math.round((this.bars[key] ?? 200) * Math.min(100, w.pct) / 100);
    return v_flex().id(`usage-row-${key}`).gap(3).flex_none()
      .child(h_flex().gap(8).items_center().flex_none()
        .child(div().w(74).flex_none().text_size(12).child(LABELS[key]))
        .child(this.track(key).child(div().absolute().h_full().left_0().w(fill).rounded(3).bg(barColor(w.pct, w.limited, t))))
        .child(div().w(36).flex_none().text_right().text_size(11).text_color(w.limited ? t.ansi1 : t.muted).child(`${w.pct}%`)))
      .child(h_flex().gap(8).items_center().flex_none()
        .child(div().w(74).flex_none())
        .child(div().flex_1().text_size(10).truncate().text_color(w.limited ? t.ansi1 : t.dim).child(countdown(w.resetsAt))));
  }

  render(cx) {
    const t = theme();
    return v_flex().id("usage").size_full().min_h(0).rounded(10).overflow_hidden()
      .bg(t.background).border_1().border_color(t.border).text_color(t.foreground).text_size(13)
      .child(h_flex().h(42).flex_none().px(14).gap(8).items_center().border_b(1).border_color(t.border)
        .child(div().font_semibold().child("Usage"))
        .child(div().flex_1())
        .child(div().text_size(11).text_color(t.dim).child(this.loading && !this.windows ? "Loading…" : "OpenCode Go")))
      .child(v_flex().id("usage-body").flex_1().min_h(0).p(10).gap(10)
        .when(this.windows, (el) => el.children(WINDOWS.map((key) => this.row(key, this.windows[key], t))))
        .when(!this.windows, (el) => el.child(div().p(6).text_size(12).text_color(t.dim)
          .child(this.error || (this.loading ? "Loading usage…" : "No usage data")))));
  }
}
