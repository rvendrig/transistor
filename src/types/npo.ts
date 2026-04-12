// NPO-specific types for radio programs and episodes
export interface NPOBroadcaster {
  id: string;
  name: string;
  description?: string;
  image?: string;
  color?: string;
}

export interface NPOProgram {
  id: string;
  title: string;
  description: string;
  image?: string;
  broadcaster: NPOBroadcaster;
  genre?: string[];
  presenters: string[];
  schedule?: {
    dayOfWeek?: string;
    time?: string;
  };
}

export interface NPOPresenter {
  id: string;
  name: string;
  bio?: string;
  image?: string;
}

export interface NPOGuest {
  name: string;
  role?: string;
  affiliation?: string;
}

export interface NPOMusic {
  title: string;
  artist: string;
  timestamp: number;
}

export interface NPOBroadcast {
  id: string;
  programId: string;
  title: string;
  description?: string;
  startTime: Date;
  endTime?: Date;
  duration: number;
  audioUrl?: string;
  image?: string;
  broadcaster: NPOBroadcaster;
  presenters: NPOPresenter[];
  guests?: NPOGuest[];
  topics?: string[];
  musicPlayed?: NPOMusic[];
  teasers?: string[];
}

export interface NPOScheduleItem {
  startTime: Date;
  endTime: Date;
  program: NPOProgram;
  broadcast?: NPOBroadcast;
}

export interface NPOChannel {
  id: string;
  name: string;
  description: string;
  image?: string;
  logo?: string;
  url: string;
  streamUrl?: string;
}
