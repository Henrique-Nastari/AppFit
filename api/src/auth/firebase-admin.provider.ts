import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import * as admin from 'firebase-admin';

@Injectable()
export class FirebaseAdminProvider {
  private initialized = false;

  constructor(private readonly config: ConfigService) {
    this.init();
  }

  private init() {
    if (this.initialized) return;

    const projectId = this.config.get<string>('FIREBASE_PROJECT_ID');
    const clientEmail = this.config.get<string>('FIREBASE_CLIENT_EMAIL');
    let privateKey = this.config.get<string>('FIREBASE_PRIVATE_KEY');
    if (privateKey) {
      privateKey = privateKey.replace(/\\n/g, '\n');
    }

    if (!admin.apps.length) {
      if (projectId && clientEmail && privateKey) {
        admin.initializeApp({
          credential: admin.credential.cert({ projectId, clientEmail, privateKey }),
        });
      } else {
        // Inicializa com default (pode falhar na verificação sem credenciais)
        admin.initializeApp();
      }
    }

    this.initialized = true;
  }

  auth(): admin.auth.Auth {
    return admin.auth();
  }
}