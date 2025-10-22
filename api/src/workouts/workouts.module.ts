import { Module } from '@nestjs/common';
import { WorkoutsController } from './workouts.controller';
import { WorkoutsService } from './workouts.service';
import { PrismaService } from '../prisma/prisma.service';
import { FirebaseAdminProvider } from '../auth/firebase-admin.provider';

@Module({
  controllers: [WorkoutsController],
  providers: [WorkoutsService, PrismaService, FirebaseAdminProvider],
})
export class WorkoutsModule {}