import { supabase } from './supabase';

interface Options {
  emailInput: HTMLInputElement;
  sendBtn: HTMLButtonElement;
  codeInput: HTMLInputElement;
  statusEl: HTMLElement;
  purpose: 'suggestion' | 'contact';
}

// Wires up the "send code" button next to an email field. The server
// enforces the code on submit; this only handles requesting it and UI state.
export function wireEmailCode({ emailInput, sendBtn, codeInput, statusEl, purpose }: Options) {
  let timer: ReturnType<typeof setInterval> | undefined;

  function cooldown(seconds: number) {
    let left = seconds;
    sendBtn.disabled = true;
    const tick = () => {
      if (left <= 0) {
        clearInterval(timer);
        sendBtn.disabled = false;
        sendBtn.textContent = '重新寄送驗證碼';
        return;
      }
      sendBtn.textContent = `${left} 秒後可重寄`;
      left--;
    };
    tick();
    timer = setInterval(tick, 1000);
  }

  sendBtn.addEventListener('click', async () => {
    const email = emailInput.value.trim();
    if (!emailInput.checkValidity() || !email) {
      emailInput.reportValidity();
      return;
    }
    sendBtn.disabled = true;
    statusEl.textContent = '寄送中...';
    const { error } = await supabase.rpc('request_email_code', { p_email: email, p_purpose: purpose });
    if (error) {
      statusEl.textContent = error.message.includes('too_many_requests')
        ? '這個信箱寄太多次了，請一小時後再試。'
        : '驗證碼寄送失敗，請確認 Email 後再試一次。';
      sendBtn.disabled = false;
      return;
    }
    statusEl.textContent = `驗證碼已寄到 ${email}，10 分鐘內有效（沒收到請看垃圾信件匣）。`;
    codeInput.disabled = false;
    codeInput.focus();
    cooldown(60);
  });

  // Changing the address invalidates whatever code was typed for the old one.
  emailInput.addEventListener('input', () => {
    codeInput.value = '';
  });
}
