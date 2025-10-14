import { Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { CreateTemplateDto } from './dto/create-template.dto';
import { CreatePostDto } from './dto/create-post.dto';

@Injectable()
export class WorkoutsService {
  constructor(private readonly prisma: PrismaService) {}

  async ensureUser(uid: string) {
    await this.prisma.user.upsert({
      where: { id: uid },
      create: { id: uid },
      update: {},
    });
  }

  async createTemplate(uid: string, dto: CreateTemplateDto) {
    await this.ensureUser(uid);

    return this.prisma.workoutTemplate.create({
      data: {
        userId: uid,
        title: dto.title,
        description: dto.description,
        intensity: dto.intensity,
        durationSeconds: dto.durationSeconds,
        exercises: {
          create: dto.exercises?.map((e, idx) => ({
            name: e.name,
            orderIndex: e.orderIndex ?? idx,
            sets: e.sets,
            reps: e.reps,
            restSeconds: e.restSeconds,
            weight: e.weight,
            rpe: e.rpe,
            notes: e.notes,
          })) ?? [],
        },
        tags: dto.tags && dto.tags.length > 0 ? {
          connectOrCreate: dto.tags.map((name) => ({
            where: { name },
            create: { name },
          })),
        } : undefined,
      },
      include: { exercises: true, tags: true },
    });
  }

  async listTemplates(uid: string) {
    return this.prisma.workoutTemplate.findMany({
      where: { userId: uid },
      orderBy: { updatedAt: 'desc' },
      include: { exercises: true, tags: true },
    });
  }

  async createPost(uid: string, dto: CreatePostDto) {
    await this.ensureUser(uid);

    let template: any = null;
    if (dto.templateId) {
      template = await this.prisma.workoutTemplate.findUnique({
        where: { id: dto.templateId },
        include: { exercises: true, tags: true },
      });
    }

    const exercisesFromTemplate = template?.exercises ?? [];
    const tagsFromTemplate = template?.tags?.map((t) => t.name) ?? [];

    return this.prisma.workoutPost.create({
      data: {
        userId: uid,
        templateId: dto.templateId,
        title: dto.title ?? template?.title ?? 'Treino',
        description: dto.description ?? template?.description,
        date: dto.date ?? new Date(),
        intensity: dto.intensity ?? template?.intensity ?? 'MEDIUM',
        durationSeconds: dto.durationSeconds ?? template?.durationSeconds,
        exercises: {
          create: (dto.exercises && dto.exercises.length > 0 ? dto.exercises : exercisesFromTemplate).map((e, idx) => ({
            name: e.name,
            orderIndex: e.orderIndex ?? idx,
            sets: e.sets,
            reps: e.reps,
            restSeconds: e.restSeconds,
            weight: e.weight,
            rpe: e.rpe,
            notes: e.notes,
            completedSets: e.completedSets,
          })),
        },
        tags: {
          connectOrCreate: (dto.tags && dto.tags.length > 0 ? dto.tags : tagsFromTemplate).map((name) => ({
            where: { name },
            create: { name },
          })),
        },
        media: dto.media && dto.media.length > 0 ? {
          create: dto.media.map((m) => ({ url: m.url, type: m.type, sizeBytes: m.sizeBytes })),
        } : undefined,
      },
      include: { exercises: true, tags: true, media: true },
    });
  }

  async listPosts(uid: string, page = 1, pageSize = 10) {
    const skip = (page - 1) * pageSize;
    const [items, total] = await this.prisma.$transaction([
      this.prisma.workoutPost.findMany({
        where: { userId: uid },
        orderBy: { date: 'desc' },
        skip,
        take: pageSize,
        include: { exercises: true, tags: true, media: true },
      }),
      this.prisma.workoutPost.count({ where: { userId: uid } }),
    ]);
    return { items, total, page, pageSize };
  }
}