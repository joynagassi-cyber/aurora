/**
 * Concentration profile editor (focus-mode spec, "profils de concentration").
 *
 * A concentration profile = a reusable focus preset (Pomodoro / Chrono +
 * blocklist + sound + linked tasks) that the agent uses when planning the
 * day's study sessions. "La planification devient un jeu d'enfant — la
 * seule chose à faire c'est travailler."
 *
 * This surface lives inside the agent flow: the user creates profiles via
 * the agent (NL: "crée-moi un profil de concentration pour RDM, 3
 * Pomodoro de 25 min, bloque TikTok"). The agent emits
 * `focus.profile` commands; this page renders the user's saved profiles
 * and lets them edit / start one directly.
 */
import { IonContent, IonHeader, IonTitle } from '@ionic/react';
import { Play, Timer, AlarmClock, Music, Shield } from 'lucide-react';
import { useState } from 'react';

export interface ConcentrationProfile {
  id: string;
  name: string;
  mode: 'pomodoro' | 'chrono';
  workMin?: number;
  pauseMin?: number;
  endTimeIso?: string;
  sound: string;
  blocklist: string[];
  taskIds: string[];
}

// Default profiles seeded on first launch (in production: loaded from
// the user's `focus_profiles` server table via the ContextAssembler).
const SEED_PROFILES: ConcentrationProfile[] = [
  {
    id: 'p1',
    name: 'RDM deep work',
    mode: 'pomodoro',
    workMin: 25,
    pauseMin: 5,
    sound: 'Pluie douce',
    blocklist: ['TikTok', 'Instagram', 'WhatsApp'],
    taskIds: [],
  },
  {
    id: 'p2',
    name: 'Examen géotechnique',
    mode: 'chrono',
    endTimeIso: '17:00',
    sound: 'Bruit blanc',
    blocklist: ['YouTube', 'TikTok'],
    taskIds: [],
  },
];

export function ConcentrationProfilesPage() {
  const [profiles] = useState<ConcentrationProfile[]>(SEED_PROFILES);

  return (
    <>
      <IonHeader>
        <IonTitle>Profils de concentration</IonTitle>
      </IonHeader>
      <IonContent>
        <div className="concentration-page">
          <div className="concentration-hint">
            <p>
              Crée des profils de concentration que l'agent applique automatiquement
              quand il planifie ta journée d'étude. Tu choisis le mode, le son et
              les apps à bloquer — le reste est automatique.
            </p>
          </div>

          {profiles.map((p) => (
            <div key={p.id} className="concentration-card">
              <div className="concentration-card-header">
                {p.mode === 'pomodoro' ? <Timer size={16} /> : <AlarmClock size={16} />}
                <h4>{p.name}</h4>
              </div>
              <div className="concentration-card-meta">
                {p.mode === 'pomodoro' && (
                  <span>{p.workMin} min travail / {p.pauseMin} min pause</span>
                )}
                {p.mode === 'chrono' && <span>Jusqu'à {p.endTimeIso}</span>}
                <span className="concentration-sound">
                  <Music size={12} aria-hidden /> {p.sound}
                </span>
                {p.blocklist.length > 0 && (
                  <span className="concentration-blocklist">
                    <Shield size={12} aria-hidden /> {p.blocklist.join(', ')}
                  </span>
                )}
              </div>
              <button type="button" className="concentration-start-btn">
                <Play size={14} />
                <span>Démarrer</span>
              </button>
            </div>
          ))}
        </div>
      </IonContent>
    </>
  );
}
