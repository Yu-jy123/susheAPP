import { preferences } from '@kit.ArkData';
import { AutomationState, defaultState } from '../model/Automation';
import { decodeState } from '../model/StateCodec';

export class StateStore {
  private prefs: preferences.Preferences;

  constructor(context: Context) {
    this.prefs = preferences.getPreferencesSync(context, { name: 'dorm_automation_state' });
  }

  load(): AutomationState {
    let raw: string = this.prefs.getSync('state', '') as string;
    if (raw.length === 0) { return defaultState(); }
    return decodeState(raw);
  }

  async save(state: AutomationState): Promise<void> {
    this.prefs.putSync('state', JSON.stringify(state));
    await this.prefs.flush();
  }
}
