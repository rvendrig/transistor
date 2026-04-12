import axios from 'axios';
import {
  NPOProgram,
  NPOBroadcast,
  NPOChannel,
  NPOScheduleItem,
  NPOBroadcaster,
  NPOPresenter,
  NPOGuest,
  NPOMusic,
  NPOItem,
} from '@/types/npo';

const NPO_API_BASE = 'https://www.nporadio.nl/api/v3';
const NPOPLUS_API_BASE = 'https://npoplus.nl/api/v3';

// NPO Channels/Broadcasters
export const NPO_CHANNELS: Record<string, NPOChannel> = {
  radio1: {
    id: 'radio1',
    name: 'NPO Radio 1',
    description: 'Nieuws, informatie en cultuur',
    url: 'https://www.nporadio1.nl',
    streamUrl: 'https://icecast.omroep.nl/radio1-bb-mp3',
  },
  radio2: {
    id: 'radio2',
    name: 'NPO Radio 2',
    description: 'Pop, rock en nostalgie',
    url: 'https://www.nporadio2.nl',
    streamUrl: 'https://icecast.omroep.nl/radio2-bb-mp3',
  },
  radio3fm: {
    id: 'radio3fm',
    name: '3FM',
    description: 'Pop, rock en jong talent',
    url: 'https://www.3fm.nl',
    streamUrl: 'https://icecast.omroep.nl/3fm-bb-mp3',
  },
  radio4: {
    id: 'radio4',
    name: 'NPO Radio 4',
    description: 'Klassieke muziek',
    url: 'https://www.nporadio4.nl',
    streamUrl: 'https://icecast.omroep.nl/radio4-bb-mp3',
  },
  radio5: {
    id: 'radio5',
    name: 'NPO Radio 5',
    description: 'Wereldmuziek en cultuur',
    url: 'https://www.nporadio5.nl',
    streamUrl: 'https://icecast.omroep.nl/radio5-bb-mp3',
  },
  radio6: {
    id: 'radio6',
    name: 'NPO Radio 6',
    description: 'Jazz en wereldmuziek',
    url: 'https://www.nporadio6.nl',
    streamUrl: 'https://icecast.omroep.nl/radio6-bb-mp3',
  },
};

interface APIProgramResponse {
  name: string;
  description: string;
  image?: string;
  presenters?: Array<{ name: string }>;
}

interface APIBroadcastResponse {
  id: string;
  title: string;
  description?: string;
  start: string;
  end?: string;
  duration: number;
  image?: string;
  presenters?: Array<{ name: string }>;
  guests?: Array<{ name: string }>;
  keywords?: string[];
}

// Fetch programs for a channel
export async function getNPOPrograms(channelId: string): Promise<NPOProgram[]> {
  try {
    // Mock data since actual API requires authentication
    const programs = getMockProgramsForChannel(channelId);
    return programs;
  } catch (error) {
    console.error('Error fetching NPO programs:', error);
    throw error;
  }
}

// Fetch recent broadcasts for a program
export async function getNPOBroadcasts(
  programId: string,
  limit: number = 50
): Promise<NPOBroadcast[]> {
  try {
    const broadcasts = getMockBroadcastsForProgram(programId, limit);
    return broadcasts;
  } catch (error) {
    console.error('Error fetching NPO broadcasts:', error);
    throw error;
  }
}

// Fetch broadcasts by date
export async function getNPOBroadcastsByDate(
  channelId: string,
  date: Date
): Promise<NPOBroadcast[]> {
  try {
    const broadcasts = getMockBroadcastsByDate(channelId, date);
    return broadcasts;
  } catch (error) {
    console.error('Error fetching broadcasts by date:', error);
    throw error;
  }
}

// Search broadcasts across all NPO content
export async function searchNPOBroadcasts(query: string): Promise<NPOBroadcast[]> {
  try {
    const results = getMockSearchResults(query);
    return results;
  } catch (error) {
    console.error('Error searching NPO broadcasts:', error);
    throw error;
  }
}

// Get channel schedule for today
export async function getNPOChannelSchedule(channelId: string): Promise<NPOScheduleItem[]> {
  try {
    const schedule = getMockSchedule(channelId);
    return schedule;
  } catch (error) {
    console.error('Error fetching channel schedule:', error);
    throw error;
  }
}

// Fetch items (segments) for a broadcast
export async function getNPOBroadcastItems(broadcastId: string): Promise<NPOItem[]> {
  try {
    const items = getMockBroadcastItems(broadcastId);
    return items;
  } catch (error) {
    console.error('Error fetching broadcast items:', error);
    throw error;
  }
}

// Mock data functions for development

function getMockProgramsForChannel(channelId: string): NPOProgram[] {
  const allPrograms: Record<string, NPOProgram[]> = {
    radio1: [
      {
        id: 'ochtendshow',
        title: 'Ochtendshow',
        description: 'De start van je dag met nieuws, muziek en interviews',
        image: 'https://via.placeholder.com/300x300?text=Ochtendshow',
        broadcaster: getNPOBroadcaster('radio1'),
        presenters: ['Jeroen Pauw', 'Matthijs van Nieuwkerk'],
        genre: ['nieuws', 'interview', 'muziek'],
      },
      {
        id: 'middag',
        title: 'Middaguren',
        description: 'Actualiteiten en reportages',
        image: 'https://via.placeholder.com/300x300?text=Middaguren',
        broadcaster: getNPOBroadcaster('radio1'),
        presenters: ['Sybille Beukers'],
        genre: ['actueel', 'reportage'],
      },
      {
        id: 'avondshow',
        title: 'Avondshow',
        description: 'Diepgravend onderzoek en documentaires',
        image: 'https://via.placeholder.com/300x300?text=Avondshow',
        broadcaster: getNPOBroadcaster('radio1'),
        presenters: ['Matthijs van Nieuwkerk'],
        genre: ['documentaire', 'onderzoek'],
      },
      {
        id: 'podcast-eo-verantwoording',
        title: 'Podcast: Eo verantwoording',
        description: 'Diepgaande interviews en debatten',
        image: 'https://via.placeholder.com/300x300?text=Eo+Verantwoording',
        broadcaster: getNPOBroadcaster('radio1'),
        presenters: ['Matthijs van Nieuwkerk'],
        genre: ['podcast', 'interview', 'actueel'],
      },
    ],
    radio2: [
      {
        id: 'early-birds',
        title: 'Early Birds',
        description: 'Pop, rock en de beste nummers',
        image: 'https://via.placeholder.com/300x300?text=Early+Birds',
        broadcaster: getNPOBroadcaster('radio2'),
        presenters: ['Menno Schroor'],
        genre: ['muziek', 'pop', 'rock'],
      },
      {
        id: 'midday-hits',
        title: 'Midday Hits',
        description: 'De beste muziek van toen en nu',
        image: 'https://via.placeholder.com/300x300?text=Midday+Hits',
        broadcaster: getNPOBroadcaster('radio2'),
        presenters: ['Frank van der Lende'],
        genre: ['muziek', 'nostalgie'],
      },
      {
        id: 'podcast-luistergoud',
        title: 'Podcast: Luistergoud',
        description: 'De mooiste en meest persoonlijke verhalen',
        image: 'https://via.placeholder.com/300x300?text=Luistergoud',
        broadcaster: getNPOBroadcaster('radio2'),
        presenters: ['Anita Witzier'],
        genre: ['podcast', 'verhalen', 'cultuur'],
      },
    ],
    radio3fm: [
      {
        id: '3fm-breakfast',
        title: '3FM Breakfast Show',
        description: 'Wake up met de beste muziek en humor',
        image: 'https://via.placeholder.com/300x300?text=3FM+Breakfast',
        broadcaster: getNPOBroadcaster('radio3fm'),
        presenters: ['Ruud de Wild'],
        genre: ['muziek', 'pop', 'rock'],
      },
      {
        id: '3fm-lunch',
        title: '3FM Lunch Show',
        description: 'De beste pop en rock nummers',
        image: 'https://via.placeholder.com/300x300?text=3FM+Lunch',
        broadcaster: getNPOBroadcaster('radio3fm'),
        presenters: ['Rob Janssen'],
        genre: ['muziek', 'pop'],
      },
      {
        id: 'podcast-3fm-funx',
        title: 'Podcast: 3FM Funx',
        description: 'Het beste uit de wereld van hip hop en R&B',
        image: 'https://via.placeholder.com/300x300?text=3FM+Funx',
        broadcaster: getNPOBroadcaster('radio3fm'),
        presenters: ['Nieuw talent'],
        genre: ['podcast', 'muziek', 'hiphop'],
      },
      {
        id: 'podcast-tomorrow-land',
        title: 'Podcast: Tomorrow Land Stories',
        description: 'Achter de schermen van het elektronische festival',
        image: 'https://via.placeholder.com/300x300?text=Tomorrow+Land',
        broadcaster: getNPOBroadcaster('radio3fm'),
        presenters: ['Festival organizers'],
        genre: ['podcast', 'muziek', 'elektro'],
      },
    ],
    radio4: [
      {
        id: 'klassiek-avond',
        title: 'Klassieke Avond',
        description: 'Klassieke muziek en opvoeringen',
        image: 'https://via.placeholder.com/300x300?text=Klassiek',
        broadcaster: getNPOBroadcaster('radio4'),
        presenters: ['Matthijs van Nieuwkerk'],
        genre: ['klassiek', 'muziek'],
      },
      {
        id: 'opera-podcast',
        title: 'Podcast: De Wereld van Opera',
        description: 'Alles wat je moet weten over opera en klassiek',
        image: 'https://via.placeholder.com/300x300?text=Opera',
        broadcaster: getNPOBroadcaster('radio4'),
        presenters: ['Lukas Heideman'],
        genre: ['podcast', 'klassiek', 'cultuur'],
      },
    ],
    radio5: [
      {
        id: 'wereld-muziek',
        title: 'Wereld Muziek Showcase',
        description: 'De beste muziek uit alle hoeken van de wereld',
        image: 'https://via.placeholder.com/300x300?text=World+Music',
        broadcaster: getNPOBroadcaster('radio5'),
        presenters: ['Anita Witzier'],
        genre: ['wereldmuziek', 'cultuur'],
      },
      {
        id: 'podcast-wereldpodcast',
        title: 'Podcast: Reizen rond de wereld',
        description: 'Verhalen uit verschillende culturen en landen',
        image: 'https://via.placeholder.com/300x300?text=World+Travel',
        broadcaster: getNPOBroadcaster('radio5'),
        presenters: ['Reizigers'],
        genre: ['podcast', 'cultuur', 'reizen'],
      },
    ],
    radio6: [
      {
        id: 'jazz-avond',
        title: 'Jazz Avond',
        description: 'De beste jazz-artiesten en live opvoeringen',
        image: 'https://via.placeholder.com/300x300?text=Jazz',
        broadcaster: getNPOBroadcaster('radio6'),
        presenters: ['Willem Breuker'],
        genre: ['jazz', 'muziek'],
      },
      {
        id: 'podcast-jazz-talk',
        title: 'Podcast: Jazz Talk',
        description: 'In-depth interviews met jazzmusici',
        image: 'https://via.placeholder.com/300x300?text=Jazz+Talk',
        broadcaster: getNPOBroadcaster('radio6'),
        presenters: ['Jazz expert'],
        genre: ['podcast', 'jazz', 'interview'],
      },
    ],
  };

  return allPrograms[channelId] || [];
}

function getMockBroadcastsForProgram(programId: string, limit: number): NPOBroadcast[] {
  const now = new Date();
  const broadcasts: NPOBroadcast[] = [];

  for (let i = 0; i < limit; i++) {
    const date = new Date(now);
    date.setDate(date.getDate() - i);
    date.setHours(9, 0, 0, 0);

    broadcasts.push({
      id: `broadcast-${programId}-${i}`,
      programId,
      title: `${programId} - ${date.toLocaleDateString('nl-NL')}`,
      description: `Afleveringsinfo voor ${date.toLocaleDateString('nl-NL')}`,
      startTime: date,
      endTime: new Date(date.getTime() + 3600000),
      duration: 3600,
      audioUrl: `https://example.com/audio/${programId}/${i}.mp3`,
      broadcaster: getNPOBroadcaster('radio1'),
      presenters: [
        {
          id: 'presenter1',
          name: 'Jeroen Pauw',
          bio: 'Ervaren presentator',
        },
      ],
      guests: [
        {
          name: 'Gast van de dag',
          role: 'Expert',
          affiliation: 'Instituut',
        },
      ],
      topics: ['nieuws', 'cultuur', 'samenleving'],
      musicPlayed: [
        {
          title: 'Nummertitel',
          artist: 'Artiestnaam',
          timestamp: 300,
        },
      ],
    });
  }

  return broadcasts;
}

function getMockBroadcastsByDate(channelId: string, date: Date): NPOBroadcast[] {
  const broadcasts: NPOBroadcast[] = [];
  const programs = getMockProgramsForChannel(channelId);

  programs.forEach((program, index) => {
    const broadcastDate = new Date(date);
    broadcastDate.setHours(9 + index * 3, 0, 0, 0);

    broadcasts.push({
      id: `broadcast-${channelId}-${index}`,
      programId: program.id,
      title: program.title,
      description: program.description,
      startTime: broadcastDate,
      endTime: new Date(broadcastDate.getTime() + 3600000),
      duration: 3600,
      broadcaster: program.broadcaster,
      presenters: program.presenters.map((name) => ({
        id: name.toLowerCase().replace(' ', '-'),
        name,
      })),
      topics: program.genre,
    });
  });

  return broadcasts;
}

function getMockSearchResults(query: string): NPOBroadcast[] {
  const broadcasts: NPOBroadcast[] = [];
  const now = new Date();

  // Generate some mock results
  for (let i = 0; i < 10; i++) {
    const date = new Date(now);
    date.setDate(date.getDate() - i);

    broadcasts.push({
      id: `search-result-${i}`,
      programId: `program-${i}`,
      title: `${query} - Aflevering ${i + 1}`,
      description: `Uitzending met thema: ${query}`,
      startTime: date,
      endTime: new Date(date.getTime() + 3600000),
      duration: 3600,
      broadcaster: getNPOBroadcaster('radio1'),
      presenters: [
        {
          id: 'presenter',
          name: 'Presentator',
        },
      ],
      topics: [query, 'actueel'],
    });
  }

  return broadcasts;
}

function getMockSchedule(channelId: string): NPOScheduleItem[] {
  const schedule: NPOScheduleItem[] = [];
  const programs = getMockProgramsForChannel(channelId);
  const today = new Date();
  today.setHours(0, 0, 0, 0);

  programs.forEach((program, index) => {
    const startTime = new Date(today);
    startTime.setHours(6 + index * 3, 0, 0, 0);

    const endTime = new Date(startTime);
    endTime.setHours(endTime.getHours() + 3);

    const broadcast: NPOBroadcast = {
      id: `schedule-${index}`,
      programId: program.id,
      title: program.title,
      description: program.description,
      startTime,
      endTime,
      duration: 3 * 3600,
      broadcaster: program.broadcaster,
      presenters: program.presenters.map((name) => ({
        id: name.toLowerCase().replace(' ', '-'),
        name,
      })),
      topics: program.genre,
    };

    schedule.push({
      startTime,
      endTime,
      program,
      broadcast,
    });
  });

  return schedule;
}

function getNPOBroadcaster(channelId: string): NPOBroadcaster {
  const broadcasters: Record<string, NPOBroadcaster> = {
    radio1: {
      id: 'radio1',
      name: 'NPO Radio 1',
      description: 'Nieuws en cultuur',
      color: '#004B87',
    },
    radio2: {
      id: 'radio2',
      name: 'NPO Radio 2',
      description: 'Pop en rock',
      color: '#E31E24',
    },
    radio3fm: {
      id: 'radio3fm',
      name: '3FM',
      description: 'Pop en jong talent',
      color: '#FF6600',
    },
    radio4: {
      id: 'radio4',
      name: 'NPO Radio 4',
      description: 'Klassieke muziek',
      color: '#007934',
    },
    radio5: {
      id: 'radio5',
      name: 'NPO Radio 5',
      description: 'Wereldmuziek',
      color: '#9E1B32',
    },
    radio6: {
      id: 'radio6',
      name: 'NPO Radio 6',
      description: 'Jazz',
      color: '#007AFF',
    },
  };

  return broadcasters[channelId] || broadcasters.radio1;
}

function getMockBroadcastItems(broadcastId: string): NPOItem[] {
  const items: NPOItem[] = [];

  // Interview segment
  items.push({
    id: `item-${broadcastId}-1`,
    broadcastId,
    title: 'Interview met gast',
    description: 'Een diepgaand interview over het actuele onderwerp',
    type: 'interview',
    startTime: 300, // 5 minutes in
    duration: 900, // 15 minutes
    guests: ['Expert in het veld'],
    topics: ['actueel', 'diepgang'],
    imageUrl: 'https://via.placeholder.com/300x300?text=Interview',
    teaserText: 'Hoe kijkt deze expert aan tegen het onderwerp?',
  });

  // Music segment
  items.push({
    id: `item-${broadcastId}-2`,
    broadcastId,
    title: 'Muziek: Populaire nummers',
    description: 'Een selectie van de best draaiende nummers',
    type: 'music',
    startTime: 1200, // 20 minutes in
    duration: 600, // 10 minutes
    artist: 'Diverse artiesten',
    musicTitle: 'Hit nummers mix',
    imageUrl: 'https://via.placeholder.com/300x300?text=Muziek',
  });

  // News segment
  items.push({
    id: `item-${broadcastId}-3`,
    broadcastId,
    title: 'Actueel: Belangrijk nieuws',
    description: 'De belangrijkste nieuwsitems van het moment',
    type: 'news',
    startTime: 1800, // 30 minutes in
    duration: 480, // 8 minutes
    topics: ['nieuws', 'actueel'],
    imageUrl: 'https://via.placeholder.com/300x300?text=Nieuws',
    teaserText: 'Wat is er vandag belangrijk gebeurd?',
  });

  // Report segment
  items.push({
    id: `item-${broadcastId}-4`,
    broadcastId,
    title: 'Reportage: Dit moet je weten',
    description: 'Een diepgaande reportage over een interessant onderwerp',
    type: 'report',
    startTime: 2280, // 38 minutes in
    duration: 720, // 12 minutes
    topics: ['onderzoek', 'reportage', 'samenleving'],
    imageUrl: 'https://via.placeholder.com/300x300?text=Reportage',
    teaserText: 'Wat gebeurt er achter de schermen?',
  });

  // Topic segment
  items.push({
    id: `item-${broadcastId}-5`,
    broadcastId,
    title: 'Thema: Vandaag in focus',
    description: 'Het thema van vandaag en waarom het belangrijk is',
    type: 'topic',
    startTime: 3000, // 50 minutes in
    duration: 600, // 10 minutes
    topics: ['thema', 'focus'],
    guests: ['Meerdere sprekers'],
    imageUrl: 'https://via.placeholder.com/300x300?text=Thema',
  });

  return items;
}
