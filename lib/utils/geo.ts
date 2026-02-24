
import { Coordinates } from '../types';

/**
 * Calcula a distância entre dois pontos geográficos em metros utilizando a fórmula de Haversine.
 * Útil para validação de proximidade em sistemas de check-in.
 */
export const calculateDistance = (coord1: Coordinates, coord2: Coordinates): number => {
  const R = 6371e3; // Raio da Terra em metros
  const phi1 = (coord1.latitude * Math.PI) / 180;
  const phi2 = (coord2.latitude * Math.PI) / 180;
  const deltaPhi = ((coord2.latitude - coord1.latitude) * Math.PI) / 180;
  const deltaLambda = ((coord2.longitude - coord1.longitude) * Math.PI) / 180;

  const a =
    Math.sin(deltaPhi / 2) * Math.sin(deltaPhi / 2) +
    Math.cos(phi1) * Math.cos(phi2) * Math.sin(deltaLambda / 2) * Math.sin(deltaLambda / 2);
  
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));

  return R * c; // Distância em metros
};

/**
 * Obtém a localização atual do dispositivo através da API nativa do browser.
 * Nota: Requer permissões de 'geolocation' configuradas no manifest/metadata.
 */
export const getCurrentPosition = (): Promise<Coordinates> => {
  return new Promise((resolve, reject) => {
    if (!navigator.geolocation) {
      reject(new Error('Geolocalização não suportada pelo browser.'));
      return;
    }

    navigator.geolocation.getCurrentPosition(
      (position) => {
        resolve({
          latitude: position.coords.latitude,
          longitude: position.coords.longitude,
        });
      },
      (error) => {
        let msg = 'Erro ao obter localização.';
        if (error.code === error.PERMISSION_DENIED) msg = 'Permissão de GPS negada.';
        reject(new Error(msg));
      },
      { enableHighAccuracy: true, timeout: 5000, maximumAge: 0 }
    );
  });
};
