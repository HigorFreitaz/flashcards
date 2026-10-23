// Configure an HTTP email gateway here (SMTP/provider SDK can replace this adapter).
// The gateway receives {to, subject, text}; never log the reset token or message body.
export async function sendResetEmail(to, token) {
  if (!process.env.EMAIL_WEBHOOK_URL) {
    const error = new Error('Recuperação por e-mail ainda não configurada.'); error.status = 503; throw error;
  }
  const response = await fetch(process.env.EMAIL_WEBHOOK_URL, {
    method: 'POST', headers: { 'Content-Type': 'application/json',
      ...(process.env.EMAIL_WEBHOOK_TOKEN ? { Authorization: `Bearer ${process.env.EMAIL_WEBHOOK_TOKEN}` } : {}) },
    body: JSON.stringify({ to, subject: 'Redefinir senha do Lume',
      text: `Use este código no aplicativo para redefinir sua senha (válido por 30 minutos): ${token}` }),
    signal: AbortSignal.timeout(10000),
  });
  if (!response.ok) { const error = new Error('Não foi possível enviar o e-mail. Tente novamente.'); error.status = 503; throw error; }
}
