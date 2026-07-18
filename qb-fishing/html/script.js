let soundEnabled = true;
let audioCtx = null;

// Small synthesized sound cues via Web Audio API - no sound files/assets needed.
function playTone(freq, duration, type) {
    if (!soundEnabled) return;

    try {
        audioCtx = audioCtx || new (window.AudioContext || window.webkitAudioContext)();

        const osc = audioCtx.createOscillator();
        const gain = audioCtx.createGain();

        osc.type = type || 'sine';
        osc.frequency.value = freq;

        gain.gain.setValueAtTime(0.15, audioCtx.currentTime);
        gain.gain.exponentialRampToValueAtTime(0.001, audioCtx.currentTime + duration);

        osc.connect(gain);
        gain.connect(audioCtx.destination);

        osc.start();
        osc.stop(audioCtx.currentTime + duration);
    } catch (e) {
        // audio context can fail to init before any user gesture in some browsers - non-fatal
    }
}

window.addEventListener('message', (event) => {
    const data = event.data;
    const container = document.getElementById('fishing-container');
    const card = container.querySelector('.fishing-card');
    const label = document.getElementById('fishing-label');
    const fill = document.getElementById('progress-fill');

    switch (data.action) {
        case 'init':
            soundEnabled = !!data.sound;
            break;

        case 'startFishing':
            container.classList.remove('hidden');
            card.classList.remove('biting');
            label.textContent = 'Casting...';

            fill.style.transition = 'none';
            fill.style.width = '0%';
            void fill.offsetWidth; // force reflow so the transition below re-triggers

            fill.style.transition = `width ${data.duration}s linear`;
            fill.style.width = '100%';
            break;

        case 'bite':
            card.classList.add('biting');
            label.textContent = "Something's biting!";
            playTone(880, 0.15, 'triangle');
            break;

        case 'result':
            if (data.outcome === 'catch') {
                playTone(660, 0.2, 'sine');
                setTimeout(() => playTone(990, 0.25, 'sine'), 120);
            } else if (data.outcome === 'junk') {
                playTone(440, 0.2, 'sine');
            } else if (data.outcome === 'fail') {
                playTone(180, 0.3, 'sawtooth');
            }
            break;

        case 'stopFishing':
            container.classList.add('hidden');
            card.classList.remove('biting');
            fill.style.transition = 'none';
            fill.style.width = '0%';
            break;
    }
});
