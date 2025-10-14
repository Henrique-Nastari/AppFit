import { Type } from 'class-transformer';
import { IsArray, IsEnum, IsInt, IsNotEmpty, IsOptional, IsString, Min, ValidateNested } from 'class-validator';

export enum IntensityDto {
  LOW = 'LOW',
  MEDIUM = 'MEDIUM',
  HIGH = 'HIGH',
}

export class ExerciseTemplateDto {
  @IsString()
  @IsNotEmpty()
  name: string;

  @IsOptional()
  @IsInt()
  @Min(0)
  orderIndex?: number;

  @IsOptional()
  @IsInt()
  sets?: number;

  @IsOptional()
  @IsInt()
  reps?: number;

  @IsOptional()
  @IsInt()
  restSeconds?: number;

  @IsOptional()
  weight?: number;

  @IsOptional()
  rpe?: number;

  @IsOptional()
  @IsString()
  notes?: string;
}

export class CreateTemplateDto {
  @IsString()
  @IsNotEmpty()
  title: string;

  @IsOptional()
  @IsString()
  description?: string;

  @IsEnum(IntensityDto)
  intensity: IntensityDto;

  @IsOptional()
  @IsInt()
  durationSeconds?: number;

  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => ExerciseTemplateDto)
  exercises: ExerciseTemplateDto[];

  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  tags?: string[];
}