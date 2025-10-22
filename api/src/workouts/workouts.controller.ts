import { Body, Controller, Get, Post, Query, Req, UseGuards } from '@nestjs/common';
import { WorkoutsService } from './workouts.service';
import { FirebaseAuthGuard } from '../auth/firebase-auth.guard';
import { CreateTemplateDto } from './dto/create-template.dto';
import { CreatePostDto } from './dto/create-post.dto';

@Controller('workouts')
@UseGuards(FirebaseAuthGuard)
export class WorkoutsController {
  constructor(private readonly service: WorkoutsService) {}

  @Post('templates')
  async createTemplate(@Req() req: any, @Body() dto: CreateTemplateDto) {
    const uid = req.user.uid as string;
    return this.service.createTemplate(uid, dto);
  }

  @Get('templates')
  async listTemplates(@Req() req: any) {
    const uid = req.user.uid as string;
    return this.service.listTemplates(uid);
  }

  @Post('posts')
  async createPost(@Req() req: any, @Body() dto: CreatePostDto) {
    const uid = req.user.uid as string;
    return this.service.createPost(uid, dto);
  }

  @Get('posts')
  async listPosts(
    @Req() req: any,
    @Query('page') page = '1',
    @Query('pageSize') pageSize = '10',
  ) {
    const uid = req.user.uid as string;
    return this.service.listPosts(uid, Number(page), Number(pageSize));
  }
}