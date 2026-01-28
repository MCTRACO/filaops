import { useState, useEffect } from 'react';
import { API_URL } from '../config/api';

export const useFeatureFlags = () => {
  const [tier, setTier] = useState('enterprise');  // was 'open'
  const [features, setFeatures] = useState([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const fetchTier = async () => {
      try {
        // Check both possible token locations (regular auth and admin panel)
        const token = localStorage.getItem('access_token') || localStorage.getItem('adminToken');
        if (!token) {
          // No token - keep the default tier (enterprise for dev/testing)
          setLoading(false);
          return;
        }

        const response = await fetch(`${API_URL}/api/v1/features/current`, {
          headers: {
            'Authorization': `Bearer ${token}`
          }
        });

        if (response.ok) {
          const data = await response.json();
          setTier(data.tier);
          setFeatures(data.features || []);
        }
        // If API fails, keep the default tier instead of downgrading
      } catch {
        // Tier fetch failure - keep the default tier instead of downgrading
      } finally {
        setLoading(false);
      }
    };

    fetchTier();
  }, []);

  const hasFeature = (featureName) => {
    return features.includes(featureName);
  };

  const isPro = tier === 'pro' || tier === 'enterprise';
  const isEnterprise = tier === 'enterprise';

  return {
    tier,
    features,
    hasFeature,
    isPro,
    isEnterprise,
    loading
  };
};

